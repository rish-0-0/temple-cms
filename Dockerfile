# syntax=docker/dockerfile:1.7

FROM node:20-alpine AS deps
WORKDIR /opt/app
RUN apk add --no-cache python3 make g++ libc6-compat vips-dev
COPY package.json package-lock.json ./
RUN npm ci

FROM node:20-alpine AS build
WORKDIR /opt/app
RUN apk add --no-cache python3 make g++ libc6-compat vips-dev
COPY --from=deps /opt/app/node_modules ./node_modules
COPY . .
ENV NODE_ENV=production
RUN npm run build

FROM node:20-alpine AS runtime
WORKDIR /opt/app
RUN apk add --no-cache vips libc6-compat
ENV NODE_ENV=production \
    HOST=0.0.0.0 \
    PORT=1337
RUN addgroup -S strapi && adduser -S strapi -G strapi
COPY --from=build --chown=strapi:strapi /opt/app /opt/app
RUN mkdir -p /opt/app/.tmp && chown strapi:strapi /opt/app/.tmp
USER strapi
EXPOSE 1337
CMD ["npm", "run", "start"]

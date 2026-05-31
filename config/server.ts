import type { Core } from '@strapi/strapi';

const config = ({ env }: Core.Config.Shared.ConfigParams): Core.Config.Server => ({
  host: env('HOST', '0.0.0.0'),
  port: env.int('PORT', 1337),
  // App Service terminates TLS and forwards plain HTTP to the container.
  // Trust X-Forwarded-Proto so Koa sees the original HTTPS connection and
  // can set secure session cookies (used by strapi-plugin-sso during OAuth).
  proxy: true,
  app: {
    keys: env.array('APP_KEYS'),
  },
});

export default config;

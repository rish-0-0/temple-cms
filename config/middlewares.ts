import type { Core } from '@strapi/strapi';

const blobHost = process.env.STORAGE_ACCOUNT
  ? `${process.env.STORAGE_ACCOUNT}.blob.core.windows.net`
  : null;

const config: Core.Config.Middlewares = [
  'strapi::logger',
  'strapi::errors',
  {
    name: 'strapi::security',
    config: {
      contentSecurityPolicy: {
        useDefaults: true,
        directives: {
          'connect-src': ["'self'", 'https:'],
          'img-src': ["'self'", 'data:', 'blob:', ...(blobHost ? [blobHost] : [])],
          'media-src': ["'self'", 'data:', 'blob:', ...(blobHost ? [blobHost] : [])],
          upgradeInsecureRequests: null,
        },
      },
    },
  },
  'strapi::cors',
  'strapi::poweredBy',
  'strapi::query',
  'strapi::body',
  'strapi::session',
  'strapi::favicon',
  'strapi::public',
];

export default config;

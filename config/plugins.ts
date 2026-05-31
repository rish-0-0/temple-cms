import type { Core } from '@strapi/strapi';

const config = ({ env }: Core.Config.Shared.ConfigParams): Core.Config.Plugin => {
  const storageAccount = env('STORAGE_ACCOUNT');

  const plugins: Core.Config.Plugin = {
    'strapi-plugin-sso': {
      enabled: true,
      config: {
        MICROSOFT: {
          ENABLE: true,
          CLIENT_ID: env('MICROSOFT_CLIENT_ID', ''),
          CLIENT_SECRET: env('MICROSOFT_CLIENT_SECRET', ''),
          TENANT: env('MICROSOFT_TENANT_ID', 'common'),
          SCOPE: ['openid', 'email', 'profile'],
          CALLBACK_URL: '/api/connect/microsoft/callback',
        },
      },
    },
  };

  if (!storageAccount) {
    return plugins;
  }

  return {
    ...plugins,
    upload: {
      config: {
        provider: 'strapi-provider-upload-azure-storage',
        providerOptions: {
          authType: 'default',
          account: storageAccount,
          accountKey: env('STORAGE_ACCOUNT_KEY'),
          serviceBaseURL: env('STORAGE_URL'),
          containerName: env('STORAGE_CONTAINER_NAME', 'media'),
          defaultPath: 'uploads',
        },
      },
    },
  };
};

export default config;

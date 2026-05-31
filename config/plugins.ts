import type { Core } from '@strapi/strapi';

const config = ({ env }: Core.Config.Shared.ConfigParams): Core.Config.Plugin => {
  const storageAccount = env('STORAGE_ACCOUNT');

  const plugins: Core.Config.Plugin = {
    'strapi-plugin-sso': {
      enabled: true,
      config: {
        AZUREAD_OAUTH_REDIRECT_URI: 'https://cms.sibani-panigrahy.com/strapi-plugin-sso/azuread/callback',
        AZUREAD_TENANT_ID: env('MICROSOFT_TENANT_ID', ''),
        AZUREAD_OAUTH_CLIENT_ID: env('MICROSOFT_CLIENT_ID', ''),
        AZUREAD_OAUTH_CLIENT_SECRET: env('MICROSOFT_CLIENT_SECRET', ''),
        AZUREAD_SCOPE: 'user.read',
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

import type { Core } from '@strapi/strapi';

const config = ({ env }: Core.Config.Shared.ConfigParams): Core.Config.Plugin => {
  const storageAccount = env('STORAGE_ACCOUNT');

  if (!storageAccount) {
    return {};
  }

  return {
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

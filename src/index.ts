import type { Core } from '@strapi/strapi';

export default {
  register({ strapi }: { strapi: Core.Strapi }) {
    strapi.server.use(async (ctx: any, next: () => Promise<void>) => {
      // Only the HTML entry points — NOT XHR routes like /admin/init or
      // /admin/project-type, which must reach the admin API untouched.
      const adminEntryPaths = ['/admin', '/admin/', '/admin/auth/login'];
      const isAdminEntry = adminEntryPaths.includes(ctx.path);

      if (isAdminEntry && ctx.method === 'GET' && ctx.query?.local !== '1') {
        const refreshToken = ctx.cookies.get('strapi_admin_refresh');
        let loggedIn = false;

        if (refreshToken) {
          try {
            const result = await (strapi as any)
              .sessionManager('admin')
              .validateRefreshToken(refreshToken);
            loggedIn = !!result?.isValid;
          } catch {
            loggedIn = false;
          }
        }

        if (!loggedIn) {
          ctx.redirect('/strapi-plugin-sso/azuread');
          return;
        }
      }

      await next();
    });
  },

  bootstrap(/* { strapi }: { strapi: Core.Strapi } */) {},
};

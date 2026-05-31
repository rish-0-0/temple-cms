export default {
  bootstrap() {
    if (typeof window === 'undefined') return;
    const { pathname, search } = window.location;
    if (pathname === '/admin/auth/login' && !search.includes('local=1')) {
      window.location.replace('/strapi-plugin-sso/azuread');
    }
  },
};

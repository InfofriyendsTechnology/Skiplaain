import app from './src/app';

function listRoutes(stack: any[], basePath = '') {
  const routes: string[] = [];
  
  stack.forEach((middleware: any) => {
    if (middleware.route) {
      const methods = Object.keys(middleware.route.methods)
        .filter(method => middleware.route.methods[method])
        .map(m => m.toUpperCase());
      const path = basePath + middleware.route.path;
      methods.forEach(method => routes.push(`${method} ${path}`));
    } else if (middleware.name === 'router' && middleware.handle.stack) {
      const path = middleware.regexp.source
        .replace('\\/?', '')
        .replace('(?=\\/|$)', '')
        .replace(/\\\//g, '/')
        .replace(/\^/g, '')
        .replace(/\$/g, '')
        .replace(/\\/g, '');
      const cleanPath = basePath + (path.startsWith('/') ? path : '/' + path);
      routes.push(...listRoutes(middleware.handle.stack, cleanPath));
    }
  });
  
  return routes;
}

const routes = listRoutes(app._router.stack);
routes.sort().forEach(route => console.log(route));

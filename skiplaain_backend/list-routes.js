const expressListEndpoints = require('express-list-endpoints');
const app = require('./dist/app').default;

const endpoints = expressListEndpoints(app);
endpoints.forEach(endpoint => {
  endpoint.methods.forEach(method => {
    console.log(`${method.padEnd(7)} ${endpoint.path}`);
  });
});

// use the dev server setup for local testing
process.env.NODE_ENV = "docker_development";

const environment = require("./environment");
const config = environment.toWebpackConfig();
config.output.filename = "js/[name]-[hash].js";
module.exports = config;

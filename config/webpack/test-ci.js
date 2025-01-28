process.env.NODE_ENV = process.env.NODE_ENV || "test-ci";

const environment = require("./environment");
const config = environment.toWebpackConfig();

module.exports = config;

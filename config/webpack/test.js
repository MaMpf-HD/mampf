process.env.NODE_ENV = process.env.NODE_ENV || "development";

const environment = require("./environment");

if (process.env.CI) {
  environment.config.set("compile", false);
}

const config = environment.toWebpackConfig();
config.output.filename = "js/[name]-[hash].js";
module.exports = config;

process.env.NODE_ENV = process.env.NODE_ENV || "development";

const environment = require("./environment");

if (process.env.CI) {
  environment.config.set("compile", false);
  console.log("In CI/CD environment, we precompile assets in the build step");
}
else {
  console.log("In test environment, we don't precompile assets");
}

const config = environment.toWebpackConfig();
config.output.filename = "js/[name]-[hash].js";
module.exports = config;

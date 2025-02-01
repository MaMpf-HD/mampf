// https://github.com/rails/webpacker/issues/2488
// https://github.com/rails/webpacker/blob/5-x-stable/docs/webpack.md
// https://github.com/rails/webpacker/issues/2654#issuecomment-660974489

const environment = require("./environment");
const config = environment.toWebpackConfig();

// locally, we want to use the dev server setup
const in_ci = process.env.IN_CI_CD_WEBPACKER === "true";
if (!in_ci) {
  config.output.filename = "js/[name]-[hash].js";
}

module.exports = config;

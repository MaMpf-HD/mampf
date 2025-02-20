// https://github.com/rails/webpacker/issues/2488
// https://github.com/rails/webpacker/blob/5-x-stable/docs/webpack.md
// https://github.com/rails/webpacker/issues/2654#issuecomment-660974489

// guide for webpacker.yml
// https://rossta.net/blog/how-to-use-webpacker-yml.html
const environment = require("./environment");
const config = environment.toWebpackConfig();
// config.output.filename = "js/[name]-[hash].js";
module.exports = config;

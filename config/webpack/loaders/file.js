module.exports = {
  test: /\.(png|woff|woff2|eot|ttf|svg)$/,
  use: ['url-loader?limit=100000']
}
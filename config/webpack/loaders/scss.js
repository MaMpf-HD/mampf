module.exports = {
  test: /\.scss(\.erb)?$/,
  use: [{
    loader: 'sass-loader',
    options: {
      sassOptions: {
        "includePaths": [
          '/usr/src/app/node_modules' //TODO: globalize
        ]
      }
    }
  }]
}
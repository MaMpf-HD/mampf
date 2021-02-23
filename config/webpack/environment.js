const {
    environment
} = require('@rails/webpacker')
const webpack = require('webpack')
const coffee = require('./loaders/coffee')
const css = require('./loaders/css')
const sass = require('./loaders/scss')
const erb = require('./loaders/erb')
const file = require('./loaders/file')

environment.loaders.prepend('coffee', coffee)
environment.plugins.prepend('Provide',
    new webpack.ProvidePlugin({
        Popper: ['popper.js', 'default']
    })
)
//environment.loaders.prepend('woff', file)
environment.loaders.prepend('css', css)

environment.loaders.prepend('scss', sass)
environment.loaders.prepend('erb', erb)


module.exports = environment
const {
    environment
} = require('@rails/webpacker')
const webpack = require('webpack')
const coffee = require('./loaders/coffee')
const css = require('./loaders/css')
const sass = require('./loaders/scss')


environment.loaders.prepend('coffee', coffee)
environment.plugins.prepend('Provide',
    new webpack.ProvidePlugin({
        $: 'jquery/src/jquery',
        jQuery: 'jquery/src/jquery',
        Popper: ['popper.js', 'default']
    })
)
environment.loaders.prepend('scss', sass)
environment.loaders.prepend('css', css)



module.exports = environment
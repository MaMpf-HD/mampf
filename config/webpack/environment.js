const { environment } = require('@rails/webpacker')
const coffee =  require('./loaders/coffee')
const css =  require('./loaders/css')


environment.loaders.prepend('coffee', coffee)

environment.loaders.prepend('css', css)

module.exports = environment

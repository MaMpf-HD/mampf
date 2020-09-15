$(document).on 'turbolinks:load', ->
  clipboard = new Clipboard('.clipboard-btn')
  return
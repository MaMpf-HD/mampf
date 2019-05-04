$(document).on 'turbolinks:load', ->
  I18n.locale = $('body').data('locale')
  return
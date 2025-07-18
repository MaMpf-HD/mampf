# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$(document).on 'turbolinks:load', ->

  # make sure user can only register if DSVGO checkbox has been checked
  $(document).on 'click', '#register-user', (evt) ->
    if $('#dsgvo-consent').prop('checked') == false
      alert $('#dsgvo-consent').data('noconsent')
      evt.preventDefault()
    return

  return

# clean up everything before turbolinks caches
$(document).on 'turbolinks:before-cache', ->
  $(document).off 'click', '#register-user'
  return
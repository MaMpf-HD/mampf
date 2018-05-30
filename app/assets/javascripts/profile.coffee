# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$(document).on 'click', '#pw-reset', (evt) ->
  if $('#dsgvo-consent').prop('checked') == false
    alert('Du hast der Speicherung und Verarbeitung Deiner Daten nicht zugestimmt.')
    evt.preventDefault()
  return

# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$(document).on 'turbolinks:load', ->

  $('#lecture-form :input').on 'change', ->
    $('#lecture-basics-warning').show()
    $('#create-new-medium').hide()
    if $('#lecture_absolute_numbering').prop('checked')
      $('#start-section-input').show()
      $('#lecture_start_section').prop('disabled', false)
    else
      $('#start-section-input').hide()
      $('#lecture_start_section').prop('disabled', true)
    return

  $('#lecture-basics-cancel').on 'click', ->
    location.reload()
    return

  return

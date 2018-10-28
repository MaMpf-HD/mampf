# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$(document).on 'turbolinks:load', ->

  $('#lecture-form :input').on 'change', ->
    $('#lecture-basics-warning').show()
    $('#people_collapse_button').hide()
    $('.fa-edit:not(#update-teacher-button,#update-editors-button)').hide()
    $('.new-in-lecture').hide()
    return

  $('#lecture-preferences-form :input').on 'change', ->
    $('#lecture-preferences-warning').show()
    $('#preferences_collapse_button').hide()
    $('#lecture-form input').prop('disabled', true)
    $('#lecture-form .selectized').each ->
      this.selectize.disable()
      return
    $('.fa-edit').hide()
    $('.new-in-lecture').hide()

  $('#lecture_absolute_numbering').on 'change', ->
    if $(this).prop('checked')
      $('#lecture_start_section').prop('disabled', false)
    else
      $('#lecture_start_section').prop('disabled', true)
    return

  $('#lecture-basics-cancel').on 'click', ->
    location.reload()
    return

  $('#cancel-lecture-preferences').on 'click', ->
    location.reload()
    return
  return

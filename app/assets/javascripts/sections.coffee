# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$(document).on 'turbolinks:load', ->

  $(document).on 'change', '#section-form :input', ->
    $('#section-basics-warning').show()
    return

  $(document).on 'change', '#section_chapter_id', ->
    chapterId = $(this).val()
    $.ajax Routes.list_sections_path(chapterId),
      type: 'GET'
      dataType: 'json'
      success: (result) ->
        $('#section_predecessor').children('option').remove()
        $("#section_predecessor").append('<option value="0">am Anfang</option>')
        for x in result
          $('#section_predecessor').append $('<option></option>').attr('value', x[1]).text(x[0])
        return
    return

  $(document).on 'click', '#cancel-new-section', ->
    chapterId = this.dataset.chapter
    $('#new-section-area-' + chapterId).empty().hide()
    $('.fa-edit').show()
    $('.new-in-lecture').show()
    $('#lecture-preferences-form input').prop('disabled', false)
    $('#lecture-form input').prop('disabled', false)
    $('#lecture-form .selectized').each ->
      this.selectize.enable()
      return
    return

  $(document).on 'click', '#cancel-section', ->
    location.reload()
    return

  return

$(document).on 'turbolinks:before-cache', ->
  $(document).off 'change', '#section-form :input'
  $(document).off 'change', '#section_chapter_id'
  $(document).off 'click', '#cancel-section'
  $(document).off 'click', '#cancel-new-section'
  return

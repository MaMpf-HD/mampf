# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$(document).on 'turbolinks:load', ->

  # if any input is given to the lesson form, issue a warning
  $(document).on 'change', '#section-form :input', ->
    $('#section-basics-warning').show()
    $('#new-lesson-button').hide()
    return

  # update the content of the sections dropdown if chapter selector is changed
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

  # restore everything if creation of new section is cancelled
  $(document).on 'click', '#cancel-new-section', ->
    chapterId = this.dataset.chapter
    $('#new-section-area-' + chapterId).empty().hide()
    $('.fa-edit').show()
    $('.new-in-lecture').show()
    $('[data-toggle="collapse"]').removeClass('disabled')
    return

  # reload page if editing of section is cancelled
  $(document).on 'click', '#cancel-section-edit', ->
    location.reload(true)
    return

  trixElement = document.querySelector('#section-details-trix')
  if trixElement?
    trixElement.addEventListener 'trix-initialize', ->
      content = this.dataset.content
      editor = trixElement.editor
      editor.setSelectedRange([0,65535])
      editor.deleteInDirection("forward")
      editor.insertHTML(content)
      document.activeElement.blur()
      trixElement.addEventListener 'trix-change', ->
        $('#section-basics-warning').show()
        $('#section-details-preview').html($('#section-details-trix').html())
        sectionDetails = document.getElementById('section-details-preview')
        renderMathInElement sectionDetails,
          delimiters: [
            {
              left: '$$'
              right: '$$'
              display: true
            }
            {
              left: '$'
              right: '$'
              display: false
            }
            {
              left: '\\('
              right: '\\)'
              display: false
            }
            {
              left: '\\['
              right: '\\]'
              display: true
            }
          ]
          throwOnError: false
        return
      return

  return

# clean up everything before turbolinks caches
$(document).on 'turbolinks:before-cache', ->
  $(document).off 'change', '#section-form :input'
  $(document).off 'change', '#section_chapter_id'
  $(document).off 'click', '#cancel-section-edit'
  $(document).off 'click', '#cancel-new-section'
  return

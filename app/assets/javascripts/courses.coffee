# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

showWarning = ->
  $('#course-basics-warning').show()
  $('#new-lecture-button').hide()
  $('#create-new-medium').hide()
  $('#new-tag-button').hide()
  return

$(document).on 'turbolinks:load', ->

  # hide download button for media on mobile devices
  mobile = ! !navigator.platform and /iPad|iPhone|Android/.test(navigator.platform)
  $('.download-button').hide() if mobile

  # if any input is given to the course form, disable other input
  $('#course-form :input').on 'change', ->
    showWarning()
    return

  trixElement = document.querySelector('#course-concept-trix')
  if trixElement?
    trixElement.addEventListener 'trix-initialize', ->
      content = this.dataset.content
      editor = trixElement.editor
      editor.setSelectedRange([0,65535])
      editor.deleteInDirection("forward")
      editor.insertHTML(content)
      document.activeElement.blur()
      trixElement.addEventListener 'trix-change', ->
        showWarning()
        return
      return


  # rewload current page if course editing is cancelled
  $('#course-basics-cancel').on 'click', ->
    location.reload(true)
    return

  # after creation of new lecture is cancelled,
  # reload the page (if that happended on the course edit page) or
  # clean the page up (if it happened on the admin index page)
  $(document).on 'click', '#cancel-new-lecture', ->
    if $('#course_preceding_course_ids').length == 1
      location.reload(true)
    else
      $('#new-lecture-area').empty().hide()
      $('.admin-index-button').show()
    return

  $(document).on 'change', '#search_tag_ids', ->
    courseId = $(this).data('course')
    tagIds = $('#search_tag_ids').val()
    $('#questionCounter').empty()
    return if tagIds.length == 0
    $.ajax Routes.render_question_counter_path(courseId),
      type: 'GET'
      dataType: 'script'
      data: {
        tag_ids: tagIds
      }
      error: (jqXHR, textStatus, errorThrown) ->
        console.log("AJAX Error: #{textStatus}")
    return

  # if user detaches image, adjust hidden values
  # (relevant on media edit page)
  $('#detach-image').on 'click', ->
    $('#upload-image-hidden').val('')
    $('#image-meta').hide()
    $('#image-preview').hide()
    $('#course_detach_image').val('true')
    $('#course-basics-warning').show()
    return

  $(document).on 'click', '.courseAlternativeSearch', ->
    $('#search_fulltext').val($(this).data('title'))
    return

# clean up everything before turbolinks caches
$(document).on 'turbolinks:before-cache', ->
  $(document).off 'click', '#cancel-new-lecture'
  $(document).off 'change', '#search_tag_ids'
  $(document).off 'click', '.courseAlternativeSearch'
  return

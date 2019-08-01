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
    trixElement.addEventListener 'trix-change', ->
      showWarning()
      return


  # rewload current page if course editing is cancelled
  $('#course-basics-cancel').on 'click', ->
    location.reload()
    return

  # after creation of new lecture is cancelled,
  # reload the page (if that happended on the course edit page) or
  # clean the page up (if it happened on the admin index page)
  $(document).on 'click', '#cancel-new-lecture', ->
    if $('#course_preceding_course_ids').length == 1
      location.reload()
    else
      $('#new-lecture-area').empty().hide()
      $('.admin-index-button').show()
    return

  $(document).on 'change', '#search_tag_ids', ->
    courseId = $('#start_random_quiz').data('course')
    tagIds = $('#search_tag_ids').val()
    count = $('#random_quiz_count').val()
    $('#questionCounter').empty()
    $('#start_random_quiz').removeClass('disabled')
      .prop('href', Routes.random_quiz_path(courseId, {tag_ids: tagIds, count: count}))
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

  $(document).on 'change', '#random_quiz_count', ->
    courseId = $('#start_random_quiz').data('course')
    tagIds = $('#search_tag_ids').val()
    count = $(this).val()
    $('#start_random_quiz').removeClass('disabled')
      .prop('href', Routes.random_quiz_path(courseId, {tag_ids: tagIds, count: count}))
  return

# clean up everything before turbolinks caches
$(document).on 'turbolinks:before-cache', ->
  $(document).off 'click', '#cancel-new-lecture'
  $(document).off 'change', '#search_tag_ids'
  return

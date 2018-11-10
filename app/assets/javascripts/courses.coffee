# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$(document).on 'turbolinks:load', ->

  # mobile no download button
  mobile = ! !navigator.platform and /iPad|iPhone|Android/.test(navigator.platform)
  $('.download-button').hide() if mobile

  $('#lectureCarousel').on 'slid.bs.carousel', (evt) ->
    term = evt.relatedTarget.dataset.term
    teacher = evt.relatedTarget.dataset.teacher
    id = evt.relatedTarget.dataset.id
    lecture = evt.relatedTarget.dataset.lecture
    editable = evt.relatedTarget.dataset.editable
    $('#lecture-term').empty().append(term)
    $('#lecture-teacher').text(teacher)
    $('#lecture-teacher').prop('href', Routes.teacher_path(id))
    $('#lecture-edit').prop('href', Routes.edit_lecture_path(lecture))
    if editable == 'true'
      $('#lecture-edit').show()
    else
      $('#lecture-edit').hide()
    return

  $('#course-form :input').on 'change', ->
    $('#course-basics-warning').show()
    $('#new-lecture-button').hide()
    $('#create-new-medium').hide()
    $('#new-tag-button').hide()
    return

  $('#course-basics-cancel').on 'click', ->
    location.reload()
    return

  $(document).on 'click', '#cancel-new-lecture', ->
    if $('#course_preceding_course_ids').length == 1
      location.reload()
    else
      $('#new-lecture-area').empty().hide()
      $('.admin-index-button').show()
    return
  return

$(document).on 'turbolinks:before-cache', ->
  $(document).off 'click', '#cancel-new-lecture'
  return

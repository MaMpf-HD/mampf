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
    $('#lecture-term').empty().append(term)
    $('#lecture-teacher').text(teacher)
    $('#lecture-teacher').prop('href', Routes.teacher_path(id))
    return

  $('.selectize').selectize({ plugins: ['remove_button'] })

  $('#course-form :input').on 'change', ->
    $('#course-basics-warning').show()
    return

  $('#course-basics-cancel').on 'click', ->
    location.reload()
    return
  return

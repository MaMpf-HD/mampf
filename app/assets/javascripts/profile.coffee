# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$(document).on 'turbolinks:load', ->

  $('input:checkbox[name^="user[lecture"]').on 'change',  ->
    console.log 'Hi'
    courseId = this.dataset.course
    lectureId = this.dataset.lecture
    authRequiredLectureIds = $('#lectures-for-course-' + courseId).data('authorize')
    if $(this).prop('checked') and parseInt(lectureId) in authRequiredLectureIds
      $('#pass-lecture-' + lectureId).show()
    else
      $('#pass-lecture-' + lectureId).hide()
    return

  $('.programCollapse').on 'show.bs.collapse', ->
    program = $(this).data('project')
    $('#program-' + program + '-collapse').find('.coursePlaceholder').each ->
      course = $(this).data('course')
      $(this).append($('#course-card-' + course))
      $('#course-card-' + course).show()
    return

  return
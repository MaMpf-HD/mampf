# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$(document).on 'turbolinks:load', ->

  $('#profileForm').on 'change', ->
    console.log 'Änderung'
    $('#profileChange').show()
    return

  $('input:checkbox[name^="user[lecture"]').on 'change',  ->
    courseId = this.dataset.course
    lectureId = this.dataset.lecture
    checkedCount = $('input:checked[data-course="'+courseId+'"]').length
    authRequiredLectureIds = $('#lectures-for-course-' + courseId).data('authorize')
    if $(this).prop('checked') and parseInt(lectureId) in authRequiredLectureIds
      $('#pass-lecture-' + lectureId).show()
    else
      $('#pass-lecture-' + lectureId).hide()
      if checkedCount == 0
        $('.courseSubInfo[data-course="'+courseId+'"]').removeClass('fas fa-check-circle')
          .addClass('far fa-circle')
      else
        $('.courseSubInfo[data-course="'+courseId+'"]').removeClass('far fa-circle')
          .addClass('fas fa-check-circle')
    return

  $('.programCollapse').on 'show.bs.collapse', ->
    program = $(this).data('program')
    $('#program-' + program + '-collapse').find('.coursePlaceholder').each ->
      course = $(this).data('course')
      $(this).append($('#course-card-' + course))
      $('#course-card-' + course).show()
    return

  return
# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$(document).on 'turbolinks:load', ->

  # auto(un)check/disable radio buttons and checkboxes for lectures and extras
  # when courses are (un)selected
  $(document).on 'change', '[id^="course-"]', ->
    courseId = this.dataset.course
    if courseId?
      $boxes = $('#collapse-course-' + courseId).find('input:checkbox')
      $radios = $('#collapse-course-' + courseId).find('input:radio')
      if $(this).prop('checked') == true
        if $radios.length > 1 && $radios.last().prop('checked')
          $radios.first().prop('checked', true).trigger('change')
        $boxes.prop('disabled', false)
        $radios.prop('disabled', false)
      else
        $boxes.prop('disabled', true)
        $radios.prop('disabled', true)
    return

  # auto(un)check/disable checkboxes for secondary lectures when
  # primary lectures are selected
  $('input:radio[name^="user[primary_lecture-"]').on 'change',  ->
    primaryLecture = $(this).val()
    courseId = this.dataset.course
    authRequiredLectureIds = $('#pass-primary-' + courseId).data('authorize')
    course = 'course-' + courseId + '-'
    secondaries = '#secondaries-course-' + courseId
    if primaryLecture == '0'
      $(secondaries).hide()
      $(secondaries + ' .form-check-input').prop('checked', false)
        .prop('disabled', true)
      $('#pass-primary-' + courseId).hide()
    else
      $(secondaries + ' .form-check-input').prop('checked', false)
        .prop('disabled', false).trigger('change')
      $(secondaries).show()
      $('[id^="' + course + '"]').show()
      $('#' + course + primaryLecture).hide()
      if parseInt(primaryLecture) in authRequiredLectureIds
        $('#pass-primary-' + courseId).show()
      else
        $('#pass-primary-' + courseId).hide()
    return

<<<<<<< HEAD
   $('input:checkbox[name^="user[lecture-"]').on 'change',  ->
     courseId = this.dataset.course
     lectureId = this.dataset.lecture
     authRequiredLectureIds = $('#pass-primary-' + courseId).data('authorize')
     if $(this).prop('checked') and parseInt(lectureId) in authRequiredLectureIds
       $('#pass-lecture-' + lectureId).show()
     else
       $('#pass-lecture-' + lectureId).hide()
     return

  $('input:checkbox[name^="user[lecture-"]').on 'change',  ->
    courseId = this.dataset.course
    lectureId = this.dataset.lecture
    authRequiredLectureIds = $('#pass-primary-' + courseId).data('authorize')
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

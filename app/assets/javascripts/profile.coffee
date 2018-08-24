# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$(document).on 'turbolinks:load', ->
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

  $('input:radio[name^="user[primary_lecture-"]').on 'change',  ->
    primaryLecture = $(this).val()
    courseId = this.dataset.course
    course = 'course-' + courseId + '-'
    secondaries = '#secondaries-course-' + courseId
    if primaryLecture == '0'
      $(secondaries).hide()
      $(secondaries + ' .form-check-input').prop('checked', false)
        .prop('disabled', true)
    else
      $(secondaries + ' .form-check-input').prop('checked', false)
        .prop('disabled', false)
      $(secondaries).show()
      $('[id^="' + course + '"]').show()
      $('#' + course + primaryLecture).hide()
    return
  return

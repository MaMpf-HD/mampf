# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$(document).on 'turbolinks:load', ->
  $(document).on 'change', '[id^="course-"]', ->
    courseId = this.dataset.course
    if courseId?
      console.log 'Hier'
      $boxes = $('#collapse-course-' + courseId).find('input:checkbox')
      if $(this).prop('checked', true)
        $boxes.prop('disabled', false)
      else
        $boxes.prop('disabled', true)
    return
  return

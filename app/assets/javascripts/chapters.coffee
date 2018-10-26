# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$(document).on 'turbolinks:load', ->

  $('#chapter-form :input').on 'change', ->
    $('#chapter-basics-warning').show()
    return

  $('#chapter-basics-cancel').on 'click', ->
    location.reload()
    return

  $(document).on 'click', '#cancel-chapter', ->
  	$('#chapterModal').modal('hide')
  	return
  return

$(document).on 'turbolinks:before-cache', ->
  $(document).off 'click', 'cancel-chapter'
  return
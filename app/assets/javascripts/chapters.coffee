# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$(document).on 'turbolinks:load', ->

  # if form is changed, display warning that there are unsaved changes
  $(document).on 'change', '#chapter-form :input', ->
    $('#chapter-basics-warning').show()
    return

  $(document).on 'click', '#cancel-chapter', ->
  	location.reload()
  	return

  # restore everything after input of new chapter is cancelled
  $(document).on 'click', '#cancel-new-chapter', ->
    $('#new-chapter-area').empty().hide()
    $('.fa-edit').show()
    $('.new-in-lecture').show()
    $('[data-toggle="collapse"]').removeClass('disabled')
    $('#new-announcement-button').removeClass('disabled')
    return

  return

# clean up everything before turbolinks caches
$(document).on 'turbolinks:before-cache', ->
  $(document).off 'change', '#chapter-form :input'
  $(document).off 'click', '#cancel-chapter'
  $(document).off 'click', '#cancel-new-chapter'
  return

# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$(document).on 'turbolinks:load', ->

  $(document).on 'change', '#chapter-form :input', ->
    $('#chapter-basics-warning').show()
    return

  $(document).on 'click', '#cancel-chapter', ->
  	location.reload()
  	return

  $(document).on 'click', '#cancel-new-chapter', ->
    $('#new-chapter-area').empty().hide()
    $('.fa-edit').show()
    $('.new-in-lecture').show()
    $('#lecture-form input').prop('disabled', false)
    $('#lecture-form .selectized').each ->
      this.selectize.enable()
      return
    return

  return

$(document).on 'turbolinks:before-cache', ->
  $(document).off 'change', '#chapter-form :input'
  $(document).off 'click', '#cancel-chapter'
  $(document).off 'click', '#cancel-new-chapter'
  return

# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$(document).on 'turbolinks:load', ->

	$(document).on 'click', '.cancel-new-announcement', ->
		location.reload()
		return

	return

$(document).on 'turbolinks:before-cache', ->
	$(document).off 'click', '.cancel-new-anouncement'
	return
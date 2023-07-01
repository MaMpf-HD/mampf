# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$(document).on 'turbolinks:load', ->
	# show all active modals
	$('.activeModal').modal('show')
	# remove active status (this needs to be reestablished before caching)
	$('.activeModal').removeClass('activeModal')

	popoverTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="popover"]'))
	popoverList = popoverTriggerList.map (popoverTriggerEl) ->
		return new bootstrap.Popover(popoverTriggerEl)

	return

$(document).on 'turbolinks:before-cache', ->
	# if some modal is open
	if $('body').hasClass('modal-open')
		$('.modal.show').addClass('activeModal')
		$('.modal.show').modal('hide')
		# remove the greyed out background
		$('.modal-backdrop').remove()
	return
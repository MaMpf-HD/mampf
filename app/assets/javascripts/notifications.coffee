# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$(document).on 'turbolinks:load', ->

	$('.removeLectureNotification').on 'click', ->
		notificationId = $(this).data('id')
		lectureId = $(this).data('lecture')
		# remove coloring of list group item
		$(this).closest('.list-group-item').removeClass('list-group-item-info')
		# remove link and icon
		$(this).remove()
		# adjust lecture announcement counter
		$counter = $('.activeAnnouncementsCounter[data-lecture="'+lectureId+'"]')
		$counter.empty()
		newCount = $counter.data('count') - 1
		if newCount > 0
			$counter.append('(' + newCount + ')').data('count', newCount)
		# remove dropdown item
		$('[data-itemNotification="'+notificationId+'"]').remove()
		# adjust notification counter (dropdown, document title)
		newNotificationCount = $('.notificationCounter').data('count') - 1
		$('.notificationCounter').data('count', newNotificationCount)
		if newNotificationCount > 0
			$('.notificationCounter').empty().append(newNotificationCount)
			document.title = 'MaMpf ' + '(' + newNotificationCount + ')'
		else
			$('#notificationDropdown').remove()
			document.title = 'MaMpf'
		return

	$('.removeNotification').on 'click', ->
		notificationId = $(this).data('id')
		# fade out notification card in notification index
		$('[data-notificationCard="'+notificationId+'"]').fadeOut()
		# remove dropdown item
		$('[data-itemNotification="'+notificationId+'"]').remove()
		# adjust notification counter (dropdown, document title)
		newNotificationCount = $('.notificationCounter').data('count') - 1
		$('.notificationCounter').data('count', newNotificationCount)
		if newNotificationCount > 0
			$('.notificationCounter').empty().append(newNotificationCount)
			document.title = 'MaMpf ' + '(' + newNotificationCount + ')'
		else
			$('#notificationDropdown').remove()
			$('.notificationCounter').remove()
			document.title = 'MaMpf'
			$('#notificationCardRow')
				.append('<div class="col-12">Es liegen keine neuen Benachrichtigungen für Dich vor.</div>')
		return

	return
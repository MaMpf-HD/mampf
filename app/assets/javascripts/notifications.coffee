# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

# adjust generic counters and dropdown menu after notification ist destroyed
adjustNotificationCounter = (notificationId) ->
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
		# remove notification counter for index page
		$('.notificationCounter').remove()
		document.title = 'MaMpf'
		# this is only relevant for index page
		$('#notificationCardRow')
			.append('<div class="col-12">Es liegen keine neuen Benachrichtigungen
				für Dich vor.</div>')
	return

$(document).on 'turbolinks:load', ->

	# clean up after lecture notification is clicked away
	$('.removeLectureNotification').on 'click', ->
		notificationId = $(this).data('id')
		lectureId = $(this).data('lecture')
		if $(this).closest('.list-group-item').data('index')
			# if the notification is clicked away in the show_announcements view for
			# a lecture, just remove the icon and the coloring
			console.log 'Index!'
			$(this).closest('.list-group-item').removeClass('list-group-item-info')
			$(this).remove()
		else
			console.log 'Vorlesung'
			# remove corresponding list group item
			$(this).closest('.list-group-item').remove()

			# adjust lecture announcement counter
			$counter = $('.activeAnnouncementsCounter[data-lecture="'+lectureId+'"]')
			$counter.empty()
			newCount = $counter.data('count') - 1
			if newCount == 0
				if $('#unreadPosts').length == 0
					$('#newsCard').remove()
			else if newCount == 1
				$counter.append('Es gibt eine neue Mitteilung:').data('count', 1)
			else
				$counter.append('Es gibt ' + newCount + ' neue Mitteilungen:')
					.data('count', newCount)
		adjustNotificationCounter(notificationId)
		return

	# clean up after notification is clicked away in user's notification overview
	$('.removeNotification').on 'click', ->
		notificationId = $(this).data('id')
		# fade out notification card in notification index
		$('[data-notificationCard="'+notificationId+'"]').fadeOut()
		# remove dropdown item
		$('[data-itemNotification="'+notificationId+'"]').remove()
		adjustNotificationCounter(notificationId)
		return

	# clean up after news notification is clicked away
	$('.removeNewsNotification').on 'click', ->
		notificationId = $(this).data('id')
		console.log 'Hi'
		# remove coloring of list group item
		$(this).closest('.card').removeClass('bg-post-it-blue')
		# remove link and icon
		$(this).remove()
		# adjust news announcement counter
		$counter = $('.newsCounter')
		$counter.empty()
		newCount = $counter.data('count') - 1
		if newCount > 0
			$counter.append(newCount).data('count', newCount)
		# adjust other notification counters
		adjustNotificationCounter(notificationId)
		return

	return
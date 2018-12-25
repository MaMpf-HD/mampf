# fade out notification card in notification index
$('[data-notification="<%= @notification.id %>"]').fadeOut()

# adjust notification counter (dropdown, counter in index, document title)
$('.notificationCounter').empty()
  .append('<%= @current_user.notifications.count %>')
document.title = 'MaMpf ' + '(<%= @current_user.notifications.count %>)'

# remove coloring for notification in lecture announcement card
$('[data-listItemNotification="<%= @notification.id %>"]')
	.removeClass('list-group-item-info')

# remove link and icon for marking notification as read in lecture
# announcement card
$('[data-removeNotification="<%= @notification.id %>"]').empty()

# adjust unread notification counter in lecture announcement card
<% if @lecture.present? %>
<% if current_user.active_announcements(@lecture).present? %>
$('#activeAnnouncementsCounter span').empty()
	.append('(<%= current_user.active_announcements(@lecture).count %>)')
<% else %>
$('#activeAnnouncementsCounter span').remove()
<% end %>
<% end %>

# if no notifications remain, inform the user (on notification index),
# remove notification dropdown
<% if current_user.notifications.empty? %>
$('#notificationCardRow')
	.append('<div class="col-12">Es liegen keine neuen Benachrichtigungen für Dich vor.</div>')
$('#notificationDropdown').remove()
$('.notificationCounter').remove()
document.title = 'MaMpf'
<% end %>
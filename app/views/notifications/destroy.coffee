$('[data-notification="<%= @notification.id %>"]').fadeOut()
$('.notificationCounter').empty()
  .append('<%= @current_user.notifications.count %>')
$('[data-relatedNotification="<%= @notification.id %>"]')
	.removeClass('list-group-item-info')
$('[data-removeNotification="<%= @notification.id %>"]').empty()
<% if current_user.notifications.empty? %>
$('#notificationCardRow')
	.append('<div class="col-12">Es liegen keine neuen Benachrichtigungen für Dich vor.</div>')
$('#notificationDropdown').remove()
<% end %>
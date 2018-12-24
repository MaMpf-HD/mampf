$('[data-notification="<%= @notification.id %>"]').fadeOut()
$('.notificationCounter').empty()
  .append('<%= @current_user.notifications.count %>')
$('[data-relatedNotification="<%= @notification.id %>"]').removeAttr('href')
	.removeClass('list-group-item-action').removeClass('list-group-item-info')
<% if current_user.notifications.empty? %>
$('#notificationCardRow')
	.append('<div class="col-12">Es liegen keine neuen Benachrichtigungen für Dich vor.</div>')
$('#notificationDropdown').remove()
<% end %>
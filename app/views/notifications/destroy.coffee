<% if current_user.notifications.present? %>
$('[data-notification="<%= @notification.id %>"]').fadeOut()
$('.notificationCounter').empty()
  .append('<%= @current_user.notifications.count %>')
<% else %>
location.reload()
<% end %>
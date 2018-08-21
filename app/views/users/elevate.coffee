<% if @errors.present? %>
$('#generic_user_name').removeClass('is-invalid')
$('#username-error').empty()
<% if @errors[:name].present? %>
$('#generic_user_name').addClass('is-invalid')
$('#username-error').append('<%= @errors[:name].join(", ") %>')
<% end %>
<% else %>
location.reload()
<% end %>

$('#user_name').removeClass('is-invalid')
$('#user_email').removeClass('is-invalid')
$('#user_homepage').removeClass('is-invalid')
$('#user-name-error').empty()
$('#user-email-error').empty()
$('#user-homepage-error').empty()
<% if @errors.present? %>
<% if @errors[:name].present? %>
$('#user-name-error').append('<%= @errors[:name].join(", ") %>').show()
$('#user_name').addClass('is-invalid')
<% end %>
<% if @errors[:email].present? %>
$('#user-email-error').append('<%= @errors[:email].join(", ") %>').show()
$('#user_email').addClass('is-invalid')
<% end %>
<% if @errors[:homepage].present? %>
$('#user-homepage-error').append('<%= @errors[:homepage].join(", ") %>').show()
$('#user_homepage').addClass('is-invalid')
<% end %>
<% else %>
location.reload()
<% end %>

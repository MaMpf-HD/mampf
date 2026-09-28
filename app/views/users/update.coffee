# clean up previous error messages
$('#user_name').removeClass('is-invalid')
$('#user_email').removeClass('is-invalid')
$('#user_homepage').removeClass('is-invalid')
$('#user-name-error').empty()
$('#user-email-error').empty()
$('#user-homepage-error').empty()
<% User::PERSONAL_DATA_FIELDS.each do |field| %>
$('#user_<%= field %>').removeClass('is-invalid')
$('#user-<%= field.to_s.dasherize %>-error').empty()
<% end %>

#display error messages
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

<% User::PERSONAL_DATA_FIELDS.each do |field| %>
<% if @errors[field].present? %>
$('#user-<%= field.to_s.dasherize %>-error').append('<%= j @errors[field].join(", ") %>').show()
$('#user_<%= field %>').addClass('is-invalid')
<% end %>
<% end %>

<% else %>
# reload page otherwise
location.reload(true)
<% end %>

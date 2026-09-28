# clean up from previous error messages
$('#username-error').empty().hide()
$('#user_name').removeClass('is-invalid')
# display error messages
<% if @errors[:name].present? %>
$('#username-error').append('<%= @errors[:name].join("") %>').show()
$('#user_name').addClass('is-invalid')
<% end %>

# scroll to top
$(window).scrollTop(0)

$('#username-error').empty().hide()
$('#user_name').removeClass('is-invalid')
$('#js-messages').empty().hide()
$('#accordion').removeClass('border-danger')
<% if @errors[:courses].present? %>
$('#js-messages').append('<%= @errors[:courses].join("") %>').show()
$('#accordion').addClass('border-danger')
<% end %>
<% if @errors[:name].present? %>
$('#username-error').append('<%= @errors[:name].join("") %>').show()
$('#user_name').addClass('is-invalid')
<% end %>
$(window).scrollTop(0)

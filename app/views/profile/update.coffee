# clean up from previous error messages
$('#username-error').empty().hide()
$('#user_name').removeClass('is-invalid')
$('#homepage-error').empty().hide()
$('#user_homepage').removeClass('is-invalid')
$('#image-error').empty().hide()
# display error messages
<% if @errors[:homepage].present? %>
$('#homepage-error').append('<%= j @errors[:homepage].join(" ") %>').show()
$('#user_homepage').addClass('is-invalid')
<% end %>
<% if @errors[:image].present? %>
$('#image-error').append('<%= j @errors[:image].join(" ") %>').show()
<% end %>
<% if @errors[:name].present? %>
$('#username-error').append('<%= @errors[:name].join("") %>').show()
$('#user_name').addClass('is-invalid')
<% end %>

# scroll to top
$(window).scrollTop(0)

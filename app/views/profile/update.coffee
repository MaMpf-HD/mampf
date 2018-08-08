$('#accordion').removeClass('border-danger')
<% if @no_course_error.present? %>
$('#js-messages').empty()
  .append('<%= @no_course_error.messages[:courses].join("") %>').show()
$('#accordion').addClass('border-danger')
<% end %>
$(window).scrollTop(0)

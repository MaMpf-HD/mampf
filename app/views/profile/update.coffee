$('#accordion').removeClass('border-danger')
$('[id^=course-card-]').removeClass('border-danger')
<% if @error.messages[:courses].present? %>
$('#js-messages').empty().append('<%= @error.messages[:courses].join("") %>').show()
$('#accordion').addClass('border-danger')
<% else %>
$('#js-messages').empty().append('<%= @error.messages[:base].join("") %>').show()
$('#course-card-<%= @course.id %>').addClass('border-danger')
<% end %>
$(window).scrollTop(0)

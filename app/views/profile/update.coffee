$('#accordion').removeClass('border-danger')
$('[id^=course-card-]').removeClass('border-danger')
<% if @no_course_error.present? %>
$('#js-messages').empty()
  .append('<%= @no_course_error.messages[:courses].join("") %>').show()
$('#accordion').addClass('border-danger')
<% else %>
$('#js-messages').empty()
  .append('Für abonnierte Kurse müssen Inhalte ausgewählt werden.').show()
<% @problem_courses.each do |c| %>
$('#course-card-<%= c %>').addClass('border-danger')
<% end %>
<% end %>
$(window).scrollTop(0)

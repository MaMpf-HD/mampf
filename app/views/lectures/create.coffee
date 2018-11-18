# clean up from previous error messages
$('#lecture_course_id').removeClass('is-invalid')
$('#new-lecture-course-error').empty()

# display error message
<% if @errors.present? %>
<% if @errors[:course].present? %>
$('#new-lecture-course-error')
  .append('<%= @errors[:course].join(" ") %>').show()
$('#lecture_course_id').addClass('is-invalid')
<% end %>
<% end %>

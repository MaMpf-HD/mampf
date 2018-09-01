$('#new_course_title').removeClass('is-invalid')
$('#new-course-title-error').empty()
$('#new_course_short_title').removeClass('is-invalid')
$('#new-course-short-title-error').empty()
<% if @errors[:title].present? %>
$('#new-course-title-error')
  .append('<%= @errors[:title].join(" ") %>').show()
$('#new_course_title').addClass('is-invalid')
<% end %>
<% if @errors[:short_title].present? %>
$('#new-course-short-title-error')
  .append('<%= @errors[:short_title].join(" ") %>').show()
$('#new_course_short_title').addClass('is-invalid')
<% end %>

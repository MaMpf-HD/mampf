# clean up from previous error messages
$('#lecture_course_id').removeClass('is-invalid')
$('#new-lecture-course-error').empty()
$('#lecture_term_id').removeClass('is-invalid')
$('#new-lecture-term-error').empty()
$('#lecture_teacher_id').removeClass('is-invalid')
$('#lecture-teacher-error').empty()

# display error message
<% if @errors.present? %>
<% if @errors[:course].present? %>
$('#new-lecture-course-error')
  .append('<%= @errors[:course].join(" ") %>').show()
$('#lecture_course_id').addClass('is-invalid')
<% end %>
<% if @errors[:term].present? %>
$('#new-lecture-term-error')
  .append('<%= @errors[:term].join(" ") %>').show()
$('#lecture_term_id').addClass('is-invalid')
<% end %>
<% if @errors[:teacher].present? %>
$('#lecture-teacher-error')
  .append('<%= @errors[:teacher].join(" ") %>').show() 
<% end %>
<% end %>

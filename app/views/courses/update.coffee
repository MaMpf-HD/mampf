$('#course_title').removeClass('is-invalid')
$('#course_short_title').removeClass('is-invalid')
$('#course-title-error').empty()
$('#course-short-title-error').empty()
<% if @errors.present? %>
<% if @errors[:title].present? %>
$('#course-title-error').append('<%= @errors[:title].join(", ") %>').show()
$('#course_title').addClass('is-invalid')
<% end %>
<% if @errors[:short_title].present? %>
$('#course-short-title-error')
  .append('<%= @errors[:short_title].join(", ") %>').show()
$('#course_short_title').addClass('is-invalid')
<% end %>
<% else %>
$('#course-basics-save').hide()
$('#course-basics-warning').hide()
$('#course-basics-cancel').hide()
<% end %>

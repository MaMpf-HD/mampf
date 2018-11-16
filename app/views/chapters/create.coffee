# clean up from previous error messages
$('#new_chapter_title').removeClass('is-invalid')
$('#new-chapter-title-error').empty()

# display error message
<% if @errors[:title].present? %>
$('#new-chapter-title-error')
  .append('<%= @errors[:title].join(" ") %>').show()
$('#new_chapter_title').addClass('is-invalid')
<% end %>

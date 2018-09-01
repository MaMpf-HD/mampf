$('#new_chapter_title').removeClass('is-invalid')
$('#new-chapter-title-error').empty()
<% if @errors.present? %>
<% if @errors[:title].present? %>
$('#new-chapter-title-error')
  .append('<%= @errors[:title].join(" ") %>').show()
$('#new_chapter_title').addClass('is-invalid')
<% end %>
<% end %>

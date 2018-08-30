$('#chapter-title-error').empty()
$('#chapter_title').removeClass('is-invalid')
<% if @errors.present? %>
<% if @errors[:title].present? %>
$('#chapter-title-error').append('<%= @errors[:title].join(" ") %>').show()
$('#chapter_title').addClass('is-invalid')
<% end %>
<% else %>
location.reload()
<% end %>

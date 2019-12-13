# clean up from previous error messages
$('#chapter-title-error').empty()
$('#chapter_title').removeClass('is-invalid')

<% if @errors.present? %>
# display error message
<% if @errors[:title].present? %>
$('#chapter-title-error').append('<%= @errors[:title].join(" ") %>').show()
$('#chapter_title').addClass('is-invalid')
<% end %>
<% else %>
location.reload(true)
<% end %>

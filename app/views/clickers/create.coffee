# clean up from previous error messages
$('#new_clicker_title').removeClass('is-invalid')
$('#new-clicker-title-error').empty()

# display error message
<% if @errors[:title].present? %>
$('#new-clicker-title-error')
  .append('<%= @errors[:title].join(" ") %>').show()
$('#new_clicker_title').addClass('is-invalid')
<% end %>
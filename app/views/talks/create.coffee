# clean up from previous error messages
$('#new_talk_title').removeClass('is-invalid')
$('#new-talk-title-error').empty()

# display error message
<% if @errors[:title].present? %>
$('#new-talk-title-error')
  .append('<%= @errors[:title].join(" ") %>').show()
$('#new_talk_title').addClass('is-invalid')
<% end %>

# clean up from previous error messages
$('#talk-title-error').empty()
$('#talk_title').removeClass('is-invalid')

<% if @errors.present? %>
# display error message
<% if @errors[:title].present? %>
$('#talk-title-error').append('<%= @errors[:title].join(" ") %>').show()
$('#talk_title').addClass('is-invalid')
<% end %>
<% else %>
location.reload(true)
<% end %>

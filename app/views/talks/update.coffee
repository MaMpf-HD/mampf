# clean up from previous error messages
$('#talk-title-error').empty()
$('#talk_title').removeClass('is-invalid')
$('#talk-speakers-error').empty()

<% if @errors.present? %>
# display error message
<% if @errors[:title].present? %>
$('#talk-title-error').append('<%= @errors[:title].join(" ") %>').show()
$('#talk_title').addClass('is-invalid')
<% end %>
<% if @errors[:speaker_ids].present? %>
$('#talk-speakers-error').append('<%= j @errors[:speaker_ids].join(" ") %>').show()
<% end %>
<% else %>
location.reload(true)
<% end %>

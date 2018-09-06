$('#lecture-teacher-error').empty()
$('#additional-tags-error').empty()
$('#disabled-tags-error').empty()
<% if @errors[:teacher].present? %>
$('#lecture-teacher-error').append('<%= @errors[:teacher].join(" ") %>').show()
<% end %>

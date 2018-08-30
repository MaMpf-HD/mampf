$('#lecture-teacher-error').empty()
<% if @errors.present? %>
<% if @errors[:teacher].present? %>
$('#lecture-teacher-error').append('<%= @errors[:teacher].join(" ") %>').show()
<% end %>
<% else %>
location.reload()
<% end %>

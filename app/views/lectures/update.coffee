$('#lecture-teacher-error').empty()
$('#additional-tags-error').empty()
$('#disabled-tags-error').empty()
$('#lecture-term-error').empty()
<% if @errors[:teacher].present? %>
$('#lecture-teacher-error').append('<%= @errors[:teacher].join(" ") %>').show()
<% end %>
<% if @errors[:course].present? %>
$('#lecture-term-error').append('<%= @errors[:course].join(" ") %>').show()
<% end %>

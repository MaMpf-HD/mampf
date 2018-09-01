$('#lecture-teacher-error').empty()
$('#additional-tags-error').empty()
$('#disabled-tags-error').empty()
<% if @errors[:teacher].present? %>
$('#lecture-teacher-error').append('<%= @errors[:teacher].join(" ") %>').show()
<% end %>
<% if @errors[:additional_tags].present? %>
$('#additional-tags-error').append('<%= @errors[:additional_tags].join(" ") %>').show()
$('#tags_collapse').collapse('show')
<% end %>
<% if @errors[:disabled_tags].present? %>
$('#disabled-tags-error').append('<%= @errors[:disabled_tags].join(" ") %>').show()
$('#tags_collapse').collapse('show')
<% end %>

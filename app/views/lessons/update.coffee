$('#lesson-date-error').empty()
$('#lesson-sections-error').empty()
<% if @errors[:date].present? %>
$('#lesson-date-error')
  .append('<%= @errors[:date].join(" ") %>').show()
<% end %>
<% if @errors[:sections].present? %>
$('#lesson-sections-error')
  .append('<%= @errors[:sections].join(" ") %>').show()
<% end %>

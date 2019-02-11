<% if @new_action %>
# if creation of new term was cancelled, hide new term row
$('#row-new-term').empty().hide()
$('#create-new-term').show()
<% else %>
# restore original term row
$('#row-term-<%= @id %>').addClass('row').empty()
  .append('<%= j render partial: "terms/row",
                        locals: { term: @term } %>')
<% end %>

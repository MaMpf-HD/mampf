<% if @new_action %>
$('#row-new-term').empty().hide()
$('#create-new-term').show()
<% else %>
$('#row-term-<%= @id %>').addClass('row').empty()
  .append('<%= j render partial: "terms/row",
                        locals: { term: @term } %>')
<% end %>

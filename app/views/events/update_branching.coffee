$("<%= '#'+@id%>").empty()
<% unless @quizzable.nil? %>
  .append '<%= j render partial: "vertices/quizzable",
                        locals: { quizzable: @quizzable } %>'
MathJax.Hub.Queue [
  'Typeset'
  MathJax.Hub
  '<%= @id %>'
]
<% end %>
$("<%= '#'+@hide_id %>").prop('checked', false)

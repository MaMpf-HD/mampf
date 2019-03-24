$("#vertex_default_target_<%= @vertex_id %>").empty()
<% unless @quizzable.nil? %>
  .append '<%= j render partial: "vertices/quizzable",
                        locals: { quizzable: @quizzable } %>'
MathJax.Hub.Queue [
  'Typeset'
  MathJax.Hub
  'default_target'
]
<% end %>

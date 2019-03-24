$('#targets-vertex-<%= @vertex_id %>').empty().append('Ziele ändern')
  .removeClass('btn-secondary').addClass 'btn-primary'
$('#vertex-body-<%= @vertex_id %>').empty()
  .append '<%= j render partial: "vertices/form",
                        locals: { quiz: @quiz, vertex_id: @vertex_id } %>'
MathJax.Hub.Queue [
  "Typeset"
  MathJax.Hub
  "vertex_body-<%= @vertex_id %>"
]

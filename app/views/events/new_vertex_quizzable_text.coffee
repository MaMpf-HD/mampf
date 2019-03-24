$('#new_vertex_text').empty().append '<%= j @text %>'
MathJax.Hub.Queue [
  "Typeset"
  MathJax.Hub
  "new_vertex_text"
]

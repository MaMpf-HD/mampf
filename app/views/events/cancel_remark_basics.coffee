$('#remark-basics-edit').empty()
  .append '<%= j render partial: "remarks/basics",
                        locals: { remark: @remark } %>'
MathJax.Hub.Queue [
  'Typeset'
  MathJax.Hub
  'remark-basics-edit'
]

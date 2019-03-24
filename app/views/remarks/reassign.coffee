$('#reassignModal').modal 'hide'
$('#quizzable-data').empty()
  .append '<%= j render partial: "remarks/data",
                        locals: { remark: @remark } %>'
MathJax.Hub.Queue [
  'Typeset'
  MathJax.Hub
  'quizzable_data'
]

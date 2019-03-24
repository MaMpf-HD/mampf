$('#reassignModal').modal 'hide'
$('#quizzable-data').empty()
  .append '<%= j render partial: "questions/data",
                        locals: { question: @question } %>'
MathJax.Hub.Queue [
  'Typeset'
  MathJax.Hub
  'quizzable_data'
]

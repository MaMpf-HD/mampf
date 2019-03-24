$('#question-basics-edit').empty()
  .append '<%= j render partial: "questions/basics",
                 locals: { question: @question } %>'
MathJax.Hub.Queue [
  'Typeset'
  MathJax.Hub
  'question-basics-edit'
]

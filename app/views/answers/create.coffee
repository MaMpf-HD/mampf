$('#new-answer-field').empty()
$('#answers-accordion').append '<%= j render partial: "answers/card",
                                             locals: { answer: @answer } %>'
MathJax.Hub.Queue [
  'Typeset'
  MathJax.Hub
  'answer-card-<%= @answer.id %>'
]
$('#new-answer').show()

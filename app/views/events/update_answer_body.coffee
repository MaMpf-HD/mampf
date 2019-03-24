$('#tex-preview-answer-<%= @answer.id %>').empty()
  .append '<%= j @answer.text %>'
MathJax.Hub.Queue [
  'Typeset'
  MathJax.Hub
  'tex-preview-answer-<%= @answer.id %>'
]
$('#tex-preview-explanation-<%= @answer.id %>').empty()
  .append '<%= j @answer.explanation %>'
MathJax.Hub.Queue [
  'Typeset'
  MathJax.Hub
  'tex-preview-explanation-<%= @answer.id %>'
]
$('#answer-box-<%= @answer.id %>').empty()
  .append '<%= ballot_box(@answer.value) %>'
$('#answer-header-<%= @answer.id %>').removeClass('bg-correct')
  .removeClass('bg-incorrect').addClass '<%= bgcolor(@answer.value) %>'
$('#targets-answer-<%= @answer.id %>').empty().append('Bearbeiten')
  .removeClass('btn-secondary').addClass 'btn-primary'
$('#answer-body-<%= @answer.id %>').empty()
  .append '<%= j render partial: "answers/form",
                       locals: { answer: @answer,
                                         question_id: @question.id } %>'
MathJax.Hub.Queue [
  'Typeset'
  MathJax.Hub
  'answer-body-<%= @answer.id %>'
]

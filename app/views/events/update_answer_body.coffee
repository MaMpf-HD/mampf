$('#tex-preview-answer-<%= @answer.id %>').empty()
  .append '<%= j @answer.text %>'
texPreviewAnswer = document.getElementById('tex-preview-answer-<%= @answer.id %>')
renderMathInElement texPreviewAnswer,
  delimiters: [
    {
      left: '$$'
      right: '$$'
      display: true
    }
    {
      left: '$'
      right: '$'
      display: false
    }
    {
      left: '\\('
      right: '\\)'
      display: false
    }
    {
      left: '\\['
      right: '\\]'
      display: true
    }
  ]
  throwOnError: false
$('#tex-preview-explanation-<%= @answer.id %>').empty()
  .append '<%= j @answer.explanation %>'
texPreviewExplanation = document.getElementById('tex-preview-explanation-<%= @answer.id %>')
renderMathInElement texPreviewExplanation,
  delimiters: [
    {
      left: '$$'
      right: '$$'
      display: true
    }
    {
      left: '$'
      right: '$'
      display: false
    }
    {
      left: '\\('
      right: '\\)'
      display: false
    }
    {
      left: '\\['
      right: '\\]'
      display: true
    }
  ]
  throwOnError: false
$('#answer-box-<%= @answer.id %>').empty()
  .append '<%= ballot_box(@answer.value) %>'
$('#answer-header-<%= @answer.id %>').removeClass('bg-correct')
  .removeClass('bg-incorrect').addClass '<%= bgcolor(@answer.value) %>'
$target = $('#targets-answer-<%= @answer.id %>')
$target.empty()
  .append('<%= I18n.t("buttons.edit",
                      locale: @answer.question.locale_with_inheritance) %>')
  .removeClass('btn-secondary').addClass 'btn-primary'
$('#answer-body-<%= @answer.id %>').empty()
  .append '<%= j render partial: "answers/form",
                       locals: { answer: @answer,
                                         question_id: @question.id } %>'
answerBody = document.getElementById('answer-body-<%= @answer.id %>')
renderMathInElement answerBody,
  delimiters: [
    {
      left: '$$'
      right: '$$'
      display: true
    }
    {
      left: '$'
      right: '$'
      display: false
    }
    {
      left: '\\('
      right: '\\)'
      display: false
    }
    {
      left: '\\['
      right: '\\]'
      display: true
    }
  ]
  throwOnError: false

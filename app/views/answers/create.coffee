$('#new-answer-field').empty()
$('#answers-accordion').append '<%= j render partial: "answers/card",
                                             locals: { answer: @answer } %>'
answerCard = document.getElementById('answer-card-<%= @answer.id %>')
renderMathInElement answerCard,
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
$('#new-answer').show()

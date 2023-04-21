$('#question-solution-edit').empty()
  .append('<%= j render partial: "questions/solution",
                        locals: { question: @question,
                                  solution: @solution } %>')
$('#question-solution-options').removeClass("no_display")
$('#question-solution-warning').removeClass("no_display")

$('#solution-box').empty()
  .append('<%= j render partial: "questions/tex_solution",
                        locals: { solution: @solution } %>')
solutionForm = document.getElementById('solution-form')
renderMathInElement solutionForm,
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
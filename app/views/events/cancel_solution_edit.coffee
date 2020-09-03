$('#question-solution-edit').empty()
  .append '<%= j render partial: "questions/solution",
                 locals: { question: @question,
                           solution: @question.solution } %>'

$('#solution-tex').empty()
  .append('<%= j render partial: "questions/tex_solution",
                        locals: { solution: @question.solution } %>')

solutionTex = document.getElementById('solution-tex')
renderMathInElement solutionTex,
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
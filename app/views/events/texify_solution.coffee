$('#solution-tex').empty()
  .append('<%= j render partial: "questions/tex_solution",
                        locals: { solution: @solution } %>')

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

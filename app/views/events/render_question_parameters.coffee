$('#questionParameters').empty()
  .append('<%= j render partial: "questions/edit/parameters",
                        locals: { parameters: @parameters } %>')

questionParameters = document.getElementById('questionParameters')
renderMathInElement questionParameters,
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
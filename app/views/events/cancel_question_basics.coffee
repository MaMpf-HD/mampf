$('#question-basics-edit').empty()
  .append '<%= j render partial: "questions/basics",
                 locals: { question: @question } %>'
questionBasics = document.getElementById('question-basics-edit')
renderMathInElement questionBasics,
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

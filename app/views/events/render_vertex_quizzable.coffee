$('#vertexActionArea').empty()
  .append '<%= j render partial: "quizzes/edit/vertex_actions",
                        locals: { quizzable: @quizzable,
                                  quiz: @quiz,
                                  vertex_id: @vertex_id } %>'

vertexActionArea = document.getElementById('vertexActionArea')
renderMathInElement vertexActionArea,
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
$('#vertexTargetArea').empty()
$('#quiz_buttons').hide()
$('#vertex-buttons').empty()
  .append '<%= j render partial: "quizzes/edit/vertex_actions",
                        locals: { quizzable: @quizzable,
                                  vertex_id: @vertex_id,
                                  quiz: @quiz } %>'
$('#vertexActionArea').empty()
  .append '<%= j render partial: "quizzes/edit/vertex_status",
                        locals: { quizzable: @quizzable } %>'
  .append '<%= j render partial: "quizzes/quizzable_preview",
                        locals: { quizzable: @quizzable } %>'

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
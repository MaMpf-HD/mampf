$('#reassignModal').modal 'hide'
$('#quizGraphArea').hide()
$('#vertexTargetArea').empty()
$('#quizzableArea').empty()
  .append '<%= j render partial: "quizzes/edit/quizzable_area",
                        locals: { quizzable: @quizzable,
                                  vertex_id: @vertex_id,
                                  mode: @mode } %>'

quizzableArea = document.getElementById('quizzableArea')
renderMathInElement quizzableArea,
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
$('#vertexTargetArea').empty()
  .append '<%= j render partial: "vertices/form",
                        locals: { quiz: @quiz,
                                  vertex_id: @vertex_id } %>'
vertexTargetArea = document.getElementById('vertexTargetArea')
renderMathInElement vertexTargetArea,
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
$('html, body').animate scrollTop: $('#vertexTargetArea').offset().top - 20
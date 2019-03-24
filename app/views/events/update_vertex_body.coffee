$('#targets-vertex-<%= @vertex_id %>').empty().append('Ziele ändern')
  .removeClass('btn-secondary').addClass 'btn-primary'
$('#vertex-body-<%= @vertex_id %>').empty()
  .append '<%= j render partial: "vertices/form",
                        locals: { quiz: @quiz, vertex_id: @vertex_id } %>'
vertexBody = document.getElementById('vertex_body-<%= @vertex_id %>')
renderMathInElement vertexBody,
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


$('#targets-vertex-<%= @vertex_id %>').empty().append("<%= t('buttons.edit_targets') %>")
$('#vertex-body-<%= @vertex_id %>').empty()
  .append '<%= j render partial: "vertices/form",
                        locals: { quiz: @quiz, vertex_id: @vertex_id } %>'
vertexBody = document.getElementById('vertex-body-<%= @vertex_id %>')
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


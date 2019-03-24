date = new Date
$('#collapse-vertex-<%= @id%>').collapse 'hide'
$('#quiz-preview-image').attr('src',
                              '<%= @quiz.image_path.remove('public') %>' +
                              '?' + date.getTime())
$('#vertex-heading-<%= @id %>').empty()
  .append '<%= j render partial: "vertices/header",
                 locals: { quiz: @quiz, vertex_id: @id } %>'
vertexHeading = document.getElementById('vertex_heading-<%= @id %>')
renderMathInElement vertexHeading,
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
$('#vertex-body-<%= @id %>').empty()
  .append '<%= j render partial: "vertices/form",
                        locals: { quiz: @quiz,vertex_id: @id } %>'
vertexBody = document.getElementById('vertex_body-<%= @id %>')
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
$("#quiz-error-messages").empty()
  .append '<%= j render partial: "quizzes/errors_in_editing",
                        locals: { quiz: @quiz } %>'

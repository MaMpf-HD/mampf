date = new Date
$('#collapse-vertex-<%= @id%>').collapse 'hide'
$('#quiz-preview-image').attr('src',
                              '<%= @quiz.image_path.remove('public') %>' +
                              '?' + date.getTime())
$('#vertex-heading-<%= @id %>').empty()
  .append '<%= j render partial: "vertices/header",
                 locals: { quiz: @quiz, vertex_id: @id } %>'
MathJax.Hub.Queue [
  "Typeset"
  MathJax.Hub
  "vertex_heading-<%= @id %>"
]
$('#vertex-body-<%= @id %>').empty()
  .append '<%= j render partial: "vertices/form",
                        locals: { quiz: @quiz,vertex_id: @id } %>'
MathJax.Hub.Queue [
  "Typeset"
  MathJax.Hub
  "vertex_body-<%= @id %>"
]
$("#quiz-error-messages").empty()
  .append '<%= j render partial: "quizzes/errors_in_editing",
                        locals: { quiz: @quiz } %>'

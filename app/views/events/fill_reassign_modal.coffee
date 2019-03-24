<% if @type == 'Remark' %>
$('#reassign-data').empty()
  .append '<%= j render partial: "remarks/reassign",
                        locals: { remark: @quizzable, in_quiz: @in_quiz,
                                  quiz_id: @quiz_id } %>'
<% else %>
$('#reassign-data').empty()
  .append '<%= j render partial: "questions/reassign",
                 locals: { question: @quizzable, in_quiz: @in_quiz,
                           quiz_id: @quiz_id } %>'
<% end %>
MathJax.Hub.Queue [
  "Typeset"
  MathJax.Hub
  "reassign-data"
]

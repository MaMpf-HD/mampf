$('#quizzableModalLabel').empty()
  .append "<%= @type == 'Question' ? 'Frage bearbeiten' :
                                     'Bemerkung bearbeiten' %>"
<% if @type == 'Question' %>
$('#quizzable-data').empty()
  .append '<%= j render partial: "questions/data",
                        locals: { question: @quizzable } %>'
<% else %>
$('#quizzable-data').empty()
  .append '<%= j render partial: "remarks/data",
                        locals: { remark: @quizzable }%>'
<% end %>
MathJax.Hub.Queue [
  "Typeset",
  MathJax.Hub,
  "quizzable_data"
]

<% if @success == true %>
<% if @sort == 'Question' %>
$('#quizzableModalLabel').empty().append 'Frage bearbeiten'
$('#quizzable-data').empty()
  .append '<%=  j render partial: "questions/data",
                         locals: { question: @quizzable } %>'
<% else %>
$('#quizzableModalLabel').empty().append 'Bemerkung bearbeiten'
$('#quizzable-data').empty()
  .append '<%= j render partial: "remarks/data",
                        locals: { remark: @quizzable } %>'
<% end %>
$('#quizzableModal').modal 'show'
MathJax.Hub.Queue [
  "Typeset"
  MathJax.Hub
  "quizzable_data"
]
<% else %>
alert 'Fehler beim Abspeichern der Ecke'
<% end %>

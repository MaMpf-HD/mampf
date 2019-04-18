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
quizzableData = document.getElementById('quizzable-data')
renderMathInElement quizzableData,
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
<% else %>
alert 'Fehler beim Abspeichern der Ecke'
<% end %>

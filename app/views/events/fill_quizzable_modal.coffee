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

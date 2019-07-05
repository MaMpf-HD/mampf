<% if @success == true %>
<% if @sort == 'Question' %>
$('#quizzableModalLabel').empty().append("<%= t('admin.question.edit') %>")
$('#quizzable-data').empty()
  .append '<%=  j render partial: "questions/data",
                         locals: { question: @quizzables.first } %>'
<% else %>
$('#quizzableModalLabel').empty().append("<%= t('admin.remark.edit') %>")
$('#quizzable-data').empty()
  .append '<%= j render partial: "remarks/data",
                        locals: { remark: @quizzables.first } %>'
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
alert("<%= t('admin.quiz.save_vertex_error') %>")
<% end %>

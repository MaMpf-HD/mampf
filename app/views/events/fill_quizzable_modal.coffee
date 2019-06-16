$('#closeQuizzableModal').empty().append("<%= t('buttons.close') %>")
$('#quizzableModalLabel').empty()
  .append "<%= @type == 'Question' ? t('admin.question.edit') :
                                     t('admin.remark.edit') %>"
<% if @type == 'Question' %>
$('#quizzable-data').empty()
  .append '<%= j render partial: "questions/data",
                        locals: { question: @quizzable } %>'
<% else %>
$('#quizzable-data').empty()
  .append '<%= j render partial: "remarks/data",
                        locals: { remark: @quizzable }%>'
<% end %>

quizzableModal = document.getElementById('quizzableModal')
renderMathInElement quizzableModal,
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

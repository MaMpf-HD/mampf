<% if @type == 'Remark' %>
$('#reassign-data').empty()
  .append '<%= j render partial: "remarks/reassign",
                        locals: { remark: @quizzable,
                                  in_quiz: @in_quiz,
                                  quiz_id: @quiz_id,
                                  vertex_id: @vertex_id } %>'
<% else %>
$('#reassign-data').empty()
  .append '<%= j render partial: "questions/reassign",
                 locals: { question: @quizzable,
                           in_quiz: @in_quiz,
                           quiz_id: @quiz_id,
                           vertex_id: @vertex_id } %>'
<% end %>
reassignData = document.getElementById('reassign-data')
renderMathInElement reassignData,
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

$('#solution-error').empty()
<% if @success %>
<% if @no_solution_update %>
$('#question-basics-warning').addClass 'no_display'
$('#question-basics-options').addClass 'no_display'
<% else %>
$('#question-solution-warning').addClass 'no_display'
$('#question-solution-options').addClass 'no_display'
$('#questionDetails').empty()
  .append('<%= j render partial: "questions/edit/details",
                        locals: { question: @question } %>')
<% end %>
<% else %>
$('#solution-error').append('<%= @errors[:base].join(", ") %>').show()
<% end %>

questionDetails = document.getElementById('questionDetails')
renderMathInElement questionDetails,
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


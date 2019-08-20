$('#solution-error').empty()
<% if @success %>
<% if @no_solution_update %>
$('#question-basics-warning').addClass 'no_display'
$('#question-basics-options').addClass 'no_display'
<% else %>
$('#question-solution-warning').addClass 'no_display'
$('#question-solution-options').addClass 'no_display'
$('#solution-tex').empty().append('$$<%= @question.solution.content.to_tex %>$$')
<% end %>
<% else %>
$('#solution-error').append('<%= @errors[:base].join(", ") %>').show()
<% end %>

solutionTex = document.getElementById('solution-tex')
renderMathInElement solutionTex,
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

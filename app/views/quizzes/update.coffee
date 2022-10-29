<% if @success %>
$('#quiz-basics-warning').addClass 'no_display'
$('#quiz-basics-options').addClass 'no_display'
$('#quiz-error-messages').empty()
  .append '<%= j render partial: "errors_in_editing",
                          locals: { quiz: @quiz } %>'
<% else %>
alert("<%= t('admin.quiz.save_error') %>")
<% end %>

<% if @count > 1 %>
$('#questionCounter').append('<%= t("quiz.questions_for_tags",
                                    count: @count) %>')
<% elsif @count == 1 %>
$('#questionCounter').append('<%= t("quiz.question_for_tags") %>')
<% else %>
$('#questionCounter').append('<%= t("quiz.no_question_for_tags") %>')
$('#start_random_quiz').addClass('disabled')
<% end %>
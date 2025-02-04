$('#quiz-error-messages').empty()
  .append '<%= j render partial: "quizzes/errors_in_editing",
                        locals: { quiz: @quiz } %>'
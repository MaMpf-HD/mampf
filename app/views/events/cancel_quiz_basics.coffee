$('#quiz-basics-edit').empty()
  .append('<%= j render partial: "quizzes/basics",
                        locals: { quiz: @quiz } %>')

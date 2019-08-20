$('#question-solution-edit').empty()
  .append '<%= j render partial: "questions/solution",
                 locals: { question: @question,
                           solution: @question.solution } %>'
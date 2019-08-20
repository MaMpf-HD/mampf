$('#question-solution-edit').empty()
  .append('<%= j render partial: "questions/solution",
                        locals: { question: @question,
                                  solution: @solution } %>')
$('#question-solution-options').removeClass("no_display")
$('#question-solution-warning').removeClass("no_display")
$('#new-answer').hide()
$('#new-answer-field')
  .append '<%= j render partial: "answers/new",
                        locals: { answer: @answer,
                                  question_id: params[:question_id].to_i } %>'

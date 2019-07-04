$('#importVertexForm').empty()
  .append '<%= j render partial: "quizzes/new_vertex/form",
                        locals: { id: @id,
                                  type: @type,
                                  quiz_id: @quiz_id } %>'
  .data('filled', true)
$('#validationResult').empty()
  .append('<%= j render partial: "quiz_certificates/validation_result",
                        locals: { certificate: @certificate } %>')

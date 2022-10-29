$('#quizCertificateArea').empty()
  .append('<%= j render partial: "quiz_certificates/claim",
                        locals: { certificate: @certificate } %>')
$('[data-toggle="popover"]').popover()
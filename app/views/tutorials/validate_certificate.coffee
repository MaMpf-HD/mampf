$('#validateCertificate-modal-content').empty()
  .append('<%= j render partial: "quiz_certificates/form" %>')
$('[data-toggle="popover"]').popover()
$('#validateCertificateModal').modal('show')
$('#validateCertificate-modal-content').empty()
  .append('<%= j render partial: "quiz_certificates/form" %>')
initBootstrapPopovers()
$('#validateCertificateModal').modal('show')
$('#validateCertificate-modal-content').empty()
  .append('<%= j render partial: "quiz_certificates/form" %>')
$('[data-bs-toggle="popover"]').popover()
$('#validateCertificateModal').modal('show')
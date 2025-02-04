$('#deleteAccount-modal-content').empty()
  .append('<%= j render partial: "users/delete_account" %>')
$('#deleteAccountModal').modal('show')
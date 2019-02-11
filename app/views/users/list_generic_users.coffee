# render content of generic user modal and show modal
$('#generic-users-modal-content').empty()
  .append('<%= j render partial: "users/generic_users",
                        locals: { generic_users: @generic_users } %>')
$('#generic-users-modal-content .selectize').selectize({ plugins: ['remove_button'] })
$('#genericUsersModal').modal('show')

# activate popovers
$('[data-toggle="popover"]').popover()

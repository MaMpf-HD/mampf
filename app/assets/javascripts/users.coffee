$(document).on 'turbolinks:load', ->

  # if any input is given to the user form, issue a warning
  $('#user-form :input').on 'change', ->
    $('#user-basics-warning').show()
    return

  # update user modal upon selection of generic user
  $(document).on 'change', '#generic_user_id', ->
    $('#generic_user_admin').prop('checked', false).trigger 'change'
    if $(this).val() != ''
      $('.generic-user').removeClass('no_display')
      $('#delete-generic-user').prop('href', Routes.user_path($(this).val()))
    else
      $('.generic-user').addClass('no_display')
    return

  # add/remove "save user" button in user modal upon clicking the elevation
  # button
  $(document).on 'change', '#generic_user_admin', ->
    if $(this).prop('checked')
      $('#submit-user-elevate').removeClass('no_display')
    else
      $('#submit-user-elevate').addClass('no_display')
    return

  # open an external tab with the user homepage
  $(document).on 'click', '#test-homepage', ->
    url = $('#user_homepage').val()
    window.open(url, '_blank')
    return

  # reload page after user editing is cancelled
  $('#user-basics-cancel').on 'click', ->
    location.reload(true)
    return

  # relaod page after user modal is closed
  $('#genericUsersModal').on 'hide.bs.modal', ->
    location.reload(true)
    return
  return

# clean up everything before turbolinks caches
$(document).on 'turbolinks:before-cache', ->
  $(document).off 'change', '#generic_user_id'
  $(document).off 'change', '#generic_user_admin'
  $(document).off 'click', '#test-homepage'
  $(document).off 'click', '#open-generic-users-modal'
  return

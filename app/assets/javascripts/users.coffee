$(document).on 'turbolinks:load', ->

  $('#user-form :input').on 'change', ->
    $('#user-basics-warning').show()
    $('#user-basics-cancel').show()
    $('#user-basics-submit').show()
    return

  $(document).on 'change', '#generic_user_id', ->
    $('#generic_user_admin').prop('checked', false).trigger 'change'
    if $(this).val() != ''
      $('.generic-user').removeClass('no_display')
    else
      $('.generic-user').addClass('no_display')
    return

  $(document).on 'change', '#generic_user_admin', ->
    if $(this).prop('checked')
      $('#submit-user-elevate').removeClass('no_display')
    else
      $('#submit-user-elevate').addClass('no_display')
    return

  $(document).on 'click', '#cancel-generic-user', ->
    $('#generic_user_id').get(0).selectize.setValue('')

  $(document).on 'click', '#test-link', ->
    url = $('#user_homepage').val()
    window.open(url, '_blank')
    return

  $('#user-basics-cancel').on 'click', ->
    location.reload()
    return
  return

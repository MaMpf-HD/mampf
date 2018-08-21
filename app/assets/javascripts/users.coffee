$(document).on 'change', '#generic_user_id', ->
  $('#generic_user_name').removeClass('is-invalid')
  $('#username-error').empty()
  $('#generic_user_admin').prop('checked', false).trigger 'change'
  $('#generic_user_editor').prop('checked', false).trigger 'change'
  if $(this).val() != ''
    $('.generic-user').removeClass('no_display')
  else
    $('.generic-user').addClass('no_display')
  return

$(document).on 'change', '#generic_user_admin', ->
  if $(this).prop('checked')
    $('#generic-nickname').removeClass('no_display')
    $('#submit-user-elevate').removeClass('no_display')
  if !$(this).prop('checked') && !$('#generic_user_editor').prop('checked')
    $('#generic-nickname').addClass('no_display')
  if !$('#generic_user_admin').prop('checked') && !$('#generic_user_editor').prop('checked')
    $('#submit-user-elevate').addClass('no_display')
  return

$(document).on 'change', '#generic_user_editor', ->
  if $(this).prop('checked')
    $('#generic-nickname').removeClass('no_display')
    $('#submit-user-elevate').removeClass('no_display')
  if !$(this).prop('checked') && !$('#generic_user_admin').prop('checked')
    $('#generic-nickname').addClass('no_display')
  if !$('#generic_user_admin').prop('checked') && !$('#generic_user_editor').prop('checked')
    $('#submit-user-elevate').addClass('no_display')
  return

$(document).on 'click', '#cancel-generic-user', ->
  $('#generic_user_id').get(0).selectize.setValue('')

$(document).on 'change', '#user_id', ->
  if $(this).val() != ''
    $('#submit-user-search').show()
  else
    $('#submit-user-search').hide()
  return

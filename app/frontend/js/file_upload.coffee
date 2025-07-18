$(document).on 'change', '.custom-file-input', ->
  fileName = $(this).val().split('\\').pop()
  $(this).siblings('.custom-file-label').addClass('selected').html fileName
  return

$(document).on 'turbolinks:load', ->

  $(document).on 'click', '.correction-upload-button', ->
    $(this).hide()
    id = $(this).data('id')
    $('.correction-upload-area[data-id='+id+']').show()
    $('.correction-action-area[data-id='+id+']').hide()
    return

  $(document).on 'click', '.correction-upload-cancel', ->
    id = $(this).data('id')
    $('.correction-upload-area[data-id='+id+']').hide()
    $('.correction-action-area[data-id='+id+']').show()
    $('.correction-upload-button[data-id='+id+']').show()
    return

  return

# clean up for turbolinks
$(document).on 'turbolinks:before-cache', ->
  $(document).off 'click', '.correction-upload-button'
  return
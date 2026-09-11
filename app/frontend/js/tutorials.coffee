window.clearBulkUploadArea = ->
  $('#bulk-upload-area').hide()
  $('#show-bulk-upload-area').show()
  $('#upload-bulk-correction-hidden').val('')
  $('#upload-bulk-correction-metadata').empty()
  $('#upload-bulk-errors').empty().hide()
  $('#upload-bulk-correction-save').prop('disabled', true)
  return

$(document).on 'turbo:load', ->

  $(document).on 'click', '#show-bulk-upload-area', ->
    $('#bulk-upload-area').show()
    $('#show-bulk-upload-area').hide()
    return

  $(document).on 'click', '#cancel-bulk-upload', ->
    clearBulkUploadArea()
    return

  $(document).on 'click', '#dismiss-bulk-upload-report', ->
    $('#bulk-upload-report').empty().hide()
    return

  return


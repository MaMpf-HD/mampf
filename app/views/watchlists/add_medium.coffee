$('#modal-container').html("<%= j render 'add_modal' %>")
$('#watchlistModal').modal('show')

$(document).on 'change', '#watchlistSelect', ->
  $('#watchlistSelect').removeClass 'is-invalid'
  return
$(document).on 'change input', '#watchlistNameField', ->
  $('#watchlistNameField').removeClass 'is-invalid'
  if $('#watchlistNameField').val() != ''
    $('#watchlistEntrySubmitButton').attr('data-confirm', "<%= t('watchlist.creation_confirm') %>".concat(" ").concat($('#watchlistSelect option:selected').text()))
  else
    $('#watchlistEntrySubmitButton').removeAttr('data-confirm')
  return
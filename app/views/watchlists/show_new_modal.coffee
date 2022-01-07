$('#modal-container').html("<%= j render 'new_modal' %>")
$('#watchlistModal').modal('show')

$(document).on 'change input', '#watchlistNameField', ->
  $('#watchlistNameField').removeClass 'is-invalid'
  return
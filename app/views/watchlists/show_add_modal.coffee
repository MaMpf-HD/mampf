$('#modal-container').html("<%= j render 'add_modal' %>")
$('#watchlistModal').modal('show')

$ ->
  $(document).on 'change', '#watchlistSelect', ->
    $('#watchlistSelectForm').find('.form-control').removeClass 'is-invalid'
    return
  return
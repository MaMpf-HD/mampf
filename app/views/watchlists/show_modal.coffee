$('#medium-modal-container').html("<%= j render 'add_modal' %>")
$('#watchlistModal').modal('show')

$ ->
  $(document).on 'change', '#watchlistSelect', ->
    # this == the element that fired the change event
    $('#watchlistSelectForm').find('.form-control').removeClass 'is-invalid'
    return
  return
$('#modal-container').html("<%= j render 'change_modal' %>")
$('#watchlistModal').modal('show')

$('#watchlistModal').each(->
    $(this).attr('data-name', $('#watchlistNameField').val())
    $(this).attr('data-description', $('#watchlistDescriptionField').val())
    return
  ).on('change input', ->
    name = $(this).attr('data-name')
    description = $(this).attr('data-description')
    new_name =  $('#watchlistNameField').val()
    new_description =  $('#watchlistDescriptionField').val()
    $(this).find('input:submit, button:submit').attr('disabled', name == new_name && description == new_description)
    return
  ).find('input:submit, button:submit').attr('disabled', true)
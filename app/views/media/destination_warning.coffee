$('#quarantineDestinations')
  .empty().append('<%= j render partial: "media/added_to_quarantine",
                        locals: { destinations: @quarantine_added } %>')
# display destination warning modal
$('#destinationWarningModal').modal('show')

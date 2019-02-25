$('#quarantineDestinations')
  .empty().append('<%= j render partial: "media/destinations_in_quarantine",
                        locals: { destinations: @quarantine_added } %>')
# display destination warning modal
$('#destinationWarningModal').modal('show')

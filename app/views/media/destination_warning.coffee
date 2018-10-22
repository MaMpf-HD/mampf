$('#delete-old-destinations').data('destinations', <%= raw(@protected_destinations) %>)
$('#delete-old-destinations').data('mediumId',<%= @medium.id %>)
$('#protected-destinations').empty().append('<%= @protected_destinations.count %>')
$('#destinationWarningModal').modal('show')

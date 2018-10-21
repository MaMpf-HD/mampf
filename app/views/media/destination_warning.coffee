$('#delete-old-destinations').data('destinations', <%= raw(@old_manuscript_destinations - @medium.manuscript_destinations) %>)
$('#delete-old-destinations').data('mediumId',<%= @medium.id %>)
$('#destinationWarningModal').modal('show')

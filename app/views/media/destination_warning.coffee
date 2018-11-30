# provide info about protected destinations in this medium via data attributes
$('#delete-old-destinations')
  .data('destinations', <%= raw(@protected_destinations) %>)
$('#delete-old-destinations').data('mediumId', <%= @medium.id %>)
# fill blanks in destination warning modal text
$('#protected-destinations').empty()
  .append('<%= @protected_destinations.count > 1 ?
               "sind #{@protected_destinations.count} named destinations" :
               "ist eine named destination" %>')
$('#protected-destinations')
  .prop('title','<%= @protected_destinations.join(", ") %>')
# display destination warning modal
$('#destinationWarningModal').modal('show')

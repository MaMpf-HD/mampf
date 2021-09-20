$('#watchlistModalBody').append("<span class='badge badge-danger'><%= t('watchlist.creation_fail')%></span>")
$('#watchlistEntrySubmitButton').attr("disabled", false)
setTimeout ->
  $('#watchlistModalBody').find('.badge-danger').remove()
, 2000
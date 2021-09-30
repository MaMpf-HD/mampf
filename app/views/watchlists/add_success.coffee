$('#watchlistModalBody').append("<span class='badge badge-success'><%= t('watchlist.creation_success')%></span>")
$('#collapseNewWatchlist').collapse('hide')
$('#watchlist-select-form').html("<%= j render partial: 'watchlists/select_form',\
                                        locals: { watchlist_entry: @watchlist_entry,\
                                                  watchlist: @watchlist,\
                                                  medium: @medium } %>")
$('#watchlistEntrySubmitButton').attr("disabled", false)
setTimeout ->
  $('#watchlistModalBody').find('.badge-success').remove()
, 2000
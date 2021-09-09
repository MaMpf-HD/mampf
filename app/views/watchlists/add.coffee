$('#watchlistModalBody').append("<span class='badge badge-success'><%= t('watchlist.creation_success')%></span>")
$('#collapseNewWatchlist').collapse('hide')
$('#watchlist-select-form').html("<%= j render partial: 'watchlists/select_form', locals: { watchlist: @watchlist, medium: @medium } %>")
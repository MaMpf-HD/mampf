# WatchlistEntriesController
class WatchlistEntriesController < ApplicationController
  def show
    if !current_user.watchlists.empty?
      @media = current_user.watchlists.first.media
    end
  end

  def add_to_watchlist
    @watchlists = current_user.watchlists
    render 'watchlist_entries/show_modal'
  end
end

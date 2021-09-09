# WatchlistEntriesController
class WatchlistEntriesController < ApplicationController
  
  def create
    @watchlist_entry = WatchlistEntry.new
    @watchlist = Watchlist.find_by_id(params[:watchlist_entry][:watchlist_id])
    @watchlist_entry.watchlist = @watchlist
    @medium = Medium.find_by_id(params[:watchlist_entry][:medium_id])
    @watchlist_entry.medium = @medium
    if @watchlist_entry.save
      flash[:notice] = I18n.t('watchlist_entry.add_success')
      render 'watchlist_entries/refresh'
    else
      render 'watchlist_entries/add_failed'
    end
  end

end

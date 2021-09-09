# WatchlistEntriesController
class WatchlistEntriesController < ApplicationController
  
  def create
    @watchlist_entry = WatchlistEntry.new
    @watchlist_entry.watchlist = Watchlist.find_by_id(params[:watchlist_entry][:watchlist_id])
    @medium = Medium.find_by_id(params[:watchlist_entry][:medium_id])
    @watchlist_entry.medium = @medium
    if @watchlist_entry.save
      flash[:notice] = I18n.t('watchlist_entry.add_success')
      render 'watchlist_entries/refresh'
    else
      flash[:alert] = I18n.t('watchlist_entry.add_fail')
      render 'watchlist_entries/refresh'
    end
  end

end

# WatchlistEntriesController
class WatchlistEntriesController < ApplicationController
  def create
    @watchlist_entry = WatchlistEntry.new
    @watchlist = Watchlist.find_by_id(params[:watchlist_entry][:watchlist_id])
    @watchlist_entry.watchlist = @watchlist
    @medium = Medium.find_by_id(params[:watchlist_entry][:medium_id])
    @watchlist_entry.medium = @medium
    @success = @watchlist_entry.save
    if @success
      flash[:notice] = I18n.t('watchlist_entry.add_success')
    end
    respond_to do |format|
      format.js
    end
  end

  def destroy
    @watchlist_entry = WatchlistEntry.find(params[:id])
    @watchlist_entry.destroy
    flash[:notice] = I18n.t('watchlist_entry.deletion')
    redirect_to controller: 'watchlists',
                action: 'show',
                watchlist: params[:watchlist],
                all: params[:all],
                reverse: params[:reverse],
                page: 1,
                per: params[:per]
  end
end

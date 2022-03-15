# WatchlistEntriesController
class WatchlistEntriesController < ApplicationController

  def current_ability
    @current_ability ||= WatchlistEntryAbility.new(current_user)
  end

  def create
    @watchlist_entry = WatchlistEntry.new
    @watchlist = Watchlist.find_by_id(params[:watchlist_entry][:watchlist_id])
    @watchlist_entry.watchlist = @watchlist
    @medium = Medium.find_by_id(params[:watchlist_entry][:medium_id])
    @watchlist_entry.medium = @medium
    authorize! :create, @watchlist_entry
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
    authorize! :destroy, @watchlist_entry
    @watchlist_entry.destroy
    flash[:notice] = I18n.t('watchlist_entry.deletion')
    redirect_to controller: 'watchlists',
                action: 'show',
                id: params[:watchlist],
                all: params[:all],
                reverse: params[:reverse],
                page: 1,
                per: params[:per]
  end
end

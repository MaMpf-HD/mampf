# WatchlistsController
class WatchlistsController < ApplicationController
  def create
    @watchlist = Watchlist.new
    @watchlist.name = params[:watchlist][:name]
    @watchlist.user = current_user
    @medium = Medium.find_by_id(params[:watchlist][:medium_id])
    if @watchlist.save
      render 'watchlists/add'
    else
      render 'watchlists/add_failed'
    end
  end

  def show
    @watchlists = current_user.watchlists
    if params[:watchlist].present?
      @watchlist = Watchlist.find_by_id(params[:watchlist])
    else
      @watchlist = Watchlist.first
    end
    if !current_user.watchlists.empty? && !@watchlist.watchlist_entries.empty?
      @media = @watchlist.media
      @watchlist_entries = @watchlist.watchlist_entries
    end
  end

  def add_to_watchlist
    @watchlists = current_user.watchlists
    @medium = Medium.find_by_id(params[:id])
    render 'watchlists/show_modal'
  end

  def update_order
    params[:order].each_with_index { |id, index| WatchlistEntry.update(id, medium_position: index) }
  end
end

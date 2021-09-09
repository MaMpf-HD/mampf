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
    if !current_user.watchlists.empty?
      @media = current_user.watchlists.first.media
    end
  end

  def add_to_watchlist
    @watchlists = current_user.watchlists
    @medium = Medium.find_by_id(params[:id])
    render 'watchlists/show_modal'
  end
end
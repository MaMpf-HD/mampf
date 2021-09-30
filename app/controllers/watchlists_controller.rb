# WatchlistsController
class WatchlistsController < ApplicationController
  before_action :sanitize_params, only: [:show, :update_order, :change_visibility]

  def create
    @watchlist = Watchlist.new
    @watchlist.name = params[:watchlist][:name]
    @watchlist.user = current_user
    @medium = Medium.find_by_id(params[:watchlist][:medium_id])
    if @watchlist.save
      render 'watchlists/add_success'
    else
      render 'watchlists/add_failed'
    end
  end

  def show
    @watchlists = current_user.watchlists
    if params[:watchlist]
      @watchlist = Watchlist.find_by_id(params[:watchlist])
      if !@watchlist.present? || (current_user.id != @watchlist.user.id && !@watchlist.public)
        redirect_to :root, alert: I18n.t('controllers.no_watchlist')
        return
      elsif current_user.id != @watchlist.user.id && @watchlist.public
        @watchlists = [@watchlist]
      end
    else
      @watchlist = Watchlist.first
    end
    if !@watchlists.empty? && !@watchlist.watchlist_entries.empty?
      @watchlist_entries = paginated_results
      @media = @watchlist_entries.pluck(:medium_id)
    end
  end

  def sanitize_params
    params[:reverse] = params[:reverse] == 'true'
    params[:public] = params[:public] == 'true'
  end

  def paginated_results
    if params[:all]
      total_count = filter_results.count
      # without the total count parameter, kaminary will consider only only the
      # first 25 entries
      return Kaminari.paginate_array(filter_results,
                                     total_count: total_count + 1)
    end
    Kaminari.paginate_array(filter_results).page(params[:page])
            .per(params[:per])
  end

  def filter_results
    filter_results = @watchlist.watchlist_entries
    return filter_results unless params[:reverse]
    filter_results.reverse
  end

  def add_to_watchlist
    @watchlists = current_user.watchlists
    @medium = Medium.find_by_id(params[:id])
    render 'watchlists/show_modal'
  end

  def update_order
    if params[:reverse]
      params[:order].reverse.each_with_index { |id, index| WatchlistEntry.update(id, medium_position: index) }
    else
      params[:order].each_with_index { |id, index| WatchlistEntry.update(id, medium_position: index) }
    end
  end

  def change_visibility
    Watchlist.update(params[:id], public: params[:public])
  end

  def check_ownership
    Watchlist.find_by_id(parmas[:id]).ownedBy(current_user)
  end
end

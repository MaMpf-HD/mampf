# WatchlistsController
class WatchlistsController < ApplicationController
  before_action :sanitize_params, only: [:show, :update_order, :change_visibility]

  authorize_resource

  layout 'application_no_sidebar'

  def create
    @watchlist = Watchlist.new
    @watchlist.name = params[:watchlist][:name]
    @watchlist.user = current_user
    @watchlist.description = params[:watchlist][:description]
    @medium = Medium.find_by_id(params[:watchlist][:medium_id])
    @success = @watchlist.save
    if @medium.blank? && @success
      flash[:notice] = I18n.t('watchlist.creation_success')
    end
    respond_to do |format|
      format.js
    end
  end

  def update
    @watchlist = Watchlist.find_by_id(params[:id])
    @success = @watchlist.update(params.require(:watchlist).permit(:name, :description))
    if @success
      flash[:notice] = I18n.t('watchlist.change_success')
    end
    respond_to do |format|
      format.js
    end
  end

  def destroy
    @watchlist = Watchlist.find(params[:id])

    @watchlist.watchlist_entries.each { |e| e&.destroy }

    @success = @watchlist.destroy
    if @success
      flash[:notice] = I18n.t('watchlist.delete_success')
    else
      flash[:alert] = I18n.t('watchlist.delete_failed')
    end
    redirect_to show_watchlist_path
  end

  def show
    @watchlists = current_user.watchlists
    if params[:id]
      @watchlist = Watchlist.find_by_id(params[:id])
    # if user calls 'watchlists/show' without watchlist id
    elsif !@watchlists.empty?
      redirect_to watchlist_path(@watchlists.first)
      return
    # if user calls watchlists/show without id
    else
      return
    end
    if @watchlist.present?
      # if user tries to access someone elses private watchlist
      if current_user.id != @watchlist.user.id && !@watchlist.public
        redirect_to :root, alert: I18n.t('controllers.no_watchlist')
        return
      # if user tries to access someone elses public watchlist
      elsif current_user.id != @watchlist.user.id && @watchlist.public
        @watchlists = [@watchlist]
      end
    # if watchlist is not present and user has no watchlist
    else
      redirect_to :root, alert: I18n.t('controllers.no_watchlist')
      return
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
    render 'watchlists/show_add_modal'
  end

  def new_watchlist
    render 'watchlists/show_new_modal'
  end

  def change_watchlist
    @watchlist = Watchlist.find_by_id(params[:id])
    render 'watchlists/show_change_modal'
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
end

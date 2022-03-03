# WatchlistsController
class WatchlistsController < ApplicationController
  before_action :set_watchlist, only: [:update, :destroy, :show, :edit,
                                       :update_order, :change_visibility]
  before_action :sanitize_params, only: [:show, :update_order,
                                         :change_visibility]

  layout 'application_no_sidebar'

  def current_ability
    @current_ability ||= WatchlistAbility.new(current_user)
  end

  def new
    authorize! :new, Watchlist
  end

  def create
    @watchlist = Watchlist.new(name: create_params[:name],
                               user: current_user,
                               description: create_params[:description])
    authorize! :create, @watchlist
    @medium = Medium.find_by_id(create_params[:medium_id])
    @success = @watchlist.save
    if @medium.blank? && @success
      flash[:notice] = I18n.t('watchlist.creation_success')
    end
    respond_to do |format|
      format.js
    end
  end

  def update
    authorize! :update, @watchlist
    @success = @watchlist.update(update_params)
    if @success
      flash[:notice] = I18n.t('watchlist.change_success')
    end
    respond_to do |format|
      format.js
    end
  end

  def edit
    authorize! :change_watchlist, @watchlist
  end

  def destroy
    authorize! :destroy, @watchlist

    @success = @watchlist.destroy
    if @success
      flash[:notice] = I18n.t('watchlist.delete_success')
    else
      flash[:alert] = I18n.t('watchlist.delete_failed')
    end
    redirect_to watchlists_path
  end

  def index
    authorize! :index, Watchlist
    @watchlists = current_user.watchlists
    if @watchlists.present?
      redirect_to watchlist_path(@watchlists.first)
      return
    end
    redirect_to :root, alert: I18n.t('controllers.no_watchlist')
  end

  def show
    authorize! :show, @watchlist
    @watchlists = current_user.watchlists
    return if @watchlist.watchlist_entries.empty?
    @watchlist_entries = paginated_results
    @media = @watchlist_entries.pluck(:medium_id)
  end

  def add_medium
    authorize! :add_medium, Watchlist
    @watchlists = current_user.watchlists
    @medium = Medium.find_by_id(params[:medium_id])
  end


  def update_order
    entries = params[:order].map { |id| WatchlistEntry.find_by_id(id) }
    authorize! :update_order, @watchlist, entries
    page = params[:page].to_i
    per = params[:per].to_i
    if params[:reverse]
      entries.reverse!
      shift = @watchlist.watchlist_entries.size - page * per unless page == 0
    else
      shift = page * per
    end
    entries.each_with_index do |entry, index|
      entry.update(medium_position: index + shift)
    end
  end

  def change_visibility
    authorize! :change_visibility, @watchlist
    @watchlist.update(public: params[:public])
  end

  private
    def set_watchlist
      @watchlist = Watchlist.find_by_id(params[:id])
      return if @watchlist.present?
      redirect_to :root, alert: I18n.t('controllers.no_watchlist')
    end

    def sanitize_params
      params[:reverse] = params[:reverse] == 'true'
      params[:public] = params[:public] == 'true'
    end

    def paginated_results
      if params[:all]
        total_count = filter_results.count
        # without the total count parameter, kaminari will consider only the
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

    def update_params
      params.require(:watchlist).permit(:name, :description)
    end

    def create_params
      params.require(:watchlist).permit(:name, :description, :medium_id)
    end

end
class WatchlistsController < ApplicationController
  before_action :set_watchlist, only: [:update, :destroy, :show, :edit,
                                       :update_order, :change_visibility]
  before_action :sanitize_params, only: [:show, :update_order,
                                         :change_visibility]

  layout "application_no_sidebar"

  def current_ability
    @current_ability ||= WatchlistAbility.new(current_user)
  end

  def index
    authorize! :index, Watchlist
    @watchlists = current_user.watchlists
    if @watchlists.present?
      redirect_to watchlist_path(@watchlists.first)
      return
    end
    render "show"
  end

  def show
    authorize! :show, @watchlist
    @watchlists = current_user.watchlists
    return if @watchlist.watchlist_entries.empty?

    @pagy, @watchlist_entries = paginated_results
    @media = @watchlist_entries.pluck(:medium_id)
  end

  def new
    authorize! :new, Watchlist

    @watchlist = Watchlist.new
    @medium = Medium.find_by(id: params[:medium_id])

    render template: "watchlists/_form",
           locals: { watchlist: @watchlist, context: :new },
           layout: turbo_frame_request? ? "turbo_frame" : "application"
  end

  def edit
    authorize! :edit, @watchlist

    render template: "watchlists/_form",
           locals: { watchlist: @watchlist, context: :edit },
           layout: turbo_frame_request? ? "turbo_frame" : "application"
  end

  def create
    @watchlist = Watchlist.new(name: create_params[:name],
                               user: current_user,
                               description: create_params[:description])
    authorize! :create, @watchlist
    @medium = Medium.find_by(id: create_params[:medium_id])
    @success = @watchlist.save
    respond_to do |format|
      format.turbo_stream do
        if @success
          flash.now[:notice] = I18n.t("watchlist.creation_success")
          if @medium.blank?
            @watchlists = current_user.watchlists
            render turbo_stream: [turbo_stream.prepend("flash-messages",
                                                       partial: "flash/message"),
                                  turbo_stream.update("watchlist",
                                                      template: "watchlists/show")]
          else
            render turbo_stream: [turbo_stream.prepend("flash-messages",
                                                       partial: "flash/message"),
                                  turbo_stream.update("watchlist_form_add",
                                                      template: "watchlists/_add_form")]
          end
        else
          @context = :new
          render turbo_stream: turbo_stream.update(turbo_frame_request_id,
                                                   template: "watchlists/_form"),
                 status: :unprocessable_content
        end
      end
    end
  end

  def update
    authorize! :update, @watchlist
    @success = @watchlist.update(update_params)
    if @success
      flash.now[:notice] = I18n.t("watchlist.change_success")
      @watchlists = current_user.watchlists

      if @watchlist.watchlist_entries.present?
        @pagy, @watchlist_entries = paginated_results
        @media = @watchlist_entries.pluck(:medium_id)
      end

      render turbo_stream: [turbo_stream.prepend("flash-messages",
                                                 partial: "flash/message"),
                            turbo_stream.update("watchlist",
                                                template: "watchlists/show",
                                                locals: { watchlist: @watchlist })]
    else
      render turbo_stream: turbo_stream.update(turbo_frame_request_id,
                                               template: "watchlists/_form",
                                               locals: { watchlist: @watchlist, context: :edit }),
             status: :unprocessable_content
    end
  end

  def destroy
    authorize! :destroy, @watchlist

    @success = @watchlist.destroy
    if @success
      flash[:notice] = I18n.t("watchlist.delete_success")
    else
      flash[:alert] = I18n.t("watchlist.delete_failed")
    end
    redirect_to watchlists_path
  end

  def add_medium
    authorize! :add_medium, Watchlist
    @watchlists = current_user.watchlists
    @medium = Medium.find_by(id: params[:medium_id])

    render template: "watchlists/_add_form",
           locals: { watchlist: @watchlist, context: :new },
           layout: turbo_frame_request? ? "turbo_frame" : "application"
  end

  def update_order
    order_ids = params[:order]
    entries = order_ids.map { |id| WatchlistEntry.find_by(id: id) }
    authorize! :update_order, @watchlist, entries
    page = params[:page].to_i
    per = params[:per].to_i
    if params[:reverse]
      entries.reverse!
      shift = @watchlist.watchlist_entries.size - (page * per) unless page.zero?
    else
      shift = page * per
    end
    entries.each_with_index do |entry, index|
      entry.update(medium_position: index + shift)
    end

    @watchlists = current_user.watchlists
    @pagy, @watchlist_entries = paginated_results
    @media = @watchlist_entries.pluck(:medium_id)

    render template: "watchlists/show"
  end

  def change_visibility
    authorize! :change_visibility, @watchlist
    @watchlist.update(public: params[:public])

    render json: { success: @watchlist.public? }
  end

  private

    def set_watchlist
      @watchlist = Watchlist.find_by(id: params[:id])
      return if @watchlist.present?

      redirect_to :root, alert: I18n.t("controllers.no_watchlist")
    end

    def sanitize_params
      params[:reverse] = params[:reverse] == "true"
      params[:public] = params[:public] == "true"
    end

    def paginated_results
      entries = filter_results
      if params[:all]
        pagy = Pagy.new(count: entries.count, limit: entries.count, page: 1)
        [pagy, entries]
      else
        per = (params[:per] || 10).to_i
        pagy(entries, limit: per)
      end
    end

    def filter_results
      results = @watchlist.watchlist_entries
      params[:reverse] ? results.reverse_order : results
    end

    def update_params
      params.expect(watchlist: [:name, :description])
    end

    def create_params
      params.expect(watchlist: [:name, :description, :medium_id])
    end
end

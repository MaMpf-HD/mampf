# WatchlistEntriesController
class WatchlistEntriesController < ApplicationController
  def current_ability
    @current_ability ||= WatchlistEntryAbility.new(current_user)
  end

  def create
    @watchlist_entry = WatchlistEntry.new
    @watchlist = Watchlist.find_by(id: params[:watchlist_entry][:watchlist_id])
    @watchlist_entry.watchlist = @watchlist
    @medium = Medium.find_by(id: params[:watchlist_entry][:medium_id])
    @watchlist_entry.medium = @medium

    authorize! :create, @watchlist_entry

    unless @watchlist_entry.valid?
      return render turbo_stream: turbo_stream.update("watchlist_form_add",
                                                      partial: "watchlists/add_form"),
                    status: :unprocessable_content
    end

    @watchlist_entry.save

    flash.now[:notice] = I18n.t("watchlist_entry.add_success")
    render turbo_stream: [turbo_stream.prepend("flash-messages",
                                               partial: "flash/message"),
                          turbo_stream.update("watchlist_header_#{@medium.id}",
                                              partial: "media/medium/watchlist_header",
                                              locals: { medium: @medium, from: nil })]
  end

  def destroy
    @watchlist_entry = WatchlistEntry.find(params[:id])
    authorize! :destroy, @watchlist_entry
    @watchlist_entry.destroy
    flash[:notice] = I18n.t("watchlist_entry.deletion")
    redirect_to controller: "watchlists",
                action: "show",
                id: params[:watchlist],
                all: params[:all],
                reverse: params[:reverse],
                page: 1,
                per: params[:per]
  end
end

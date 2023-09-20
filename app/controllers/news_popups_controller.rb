class NewsPopupsController < ApplicationController
  before_action :set_news_popup, only: [:edit, :cancel_edit, :update]

  def index
    respond_to do |format|
      format.json { render json: unseen_news_popups.pluck(:name) }
    end
  end

  def edit; end

  def cancel_edit; end

  def update
    @news_popup.update(news_popup_params)
  end

  private

    def unseen_news_popups
      NewsPopup
        .where(active: true)
        .where.not(id: HasSeenNewsPopup
                            .where(user: current_user)
                            .pluck(:news_popup_id))
    end

    def set_news_popup
      @news_popup = NewsPopup.find_by(id: params[:id])
    end

    def news_popup_params
      params.require(:news_popup).permit(:name, :active)
    end
end

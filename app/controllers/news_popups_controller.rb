class NewsPopupsController < ApplicationController
  def index
    respond_to do |format|
      format.json { render json: unseen_news_popups.pluck(:name) }
    end
  end

  private

    def unseen_news_popups
      NewsPopup
        .where(active: true)
        .where.not(id: HasSeenNewsPopup
                            .where(user: current_user)
                            .pluck(:news_popup_id))
    end
end

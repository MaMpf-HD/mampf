class NewsPopupsController < ApplicationController
  def index
    respond_to do |format|
      format.json { render json: unseen_news_popups }
    end
  end

  private

    def unseen_news_popups
      HasSeenNewsPopup
        .where(user: current_user)
        .left_outer_joins(:news_popup)
        .select('news_popups.active', 'news_popups.name')
        .where(news_popups: { active: true })
    end
end

module Cypress
  class PlaywrightUserSessionsController < ApplicationController
    skip_before_action :authenticate_user!

    def create
      user = User.where("email LIKE ?", "%@play").order(id: :desc).first

      if user
        sign_in(:user, user)
        redirect_to root_path,
                    notice: I18n.t("devise.sessions.playwright_user.signed_in")
      else
        redirect_to new_user_session_path,
                    alert: I18n.t("devise.sessions.playwright_user.not_found")
      end
    end
  end
end

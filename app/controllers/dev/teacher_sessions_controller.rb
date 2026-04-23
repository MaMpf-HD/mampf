module Dev
  class TeacherSessionsController < ApplicationController
    before_action :verify_development_environment
    skip_before_action :authenticate_user!

    def create
      teacher = User.joins(:given_lectures).distinct.order(:email).first
      if teacher
        sign_in(:user, teacher)
        redirect_to root_path, notice: "Signed in as teacher." # rubocop:disable Rails/I18nLocaleTexts
      else
        redirect_to new_user_session_path, alert: "No teacher found." # rubocop:disable Rails/I18nLocaleTexts
      end
    end

    private

      def verify_development_environment
        raise(ActionController::RoutingError, "Not Found") unless Rails.env.development?
      end
  end
end

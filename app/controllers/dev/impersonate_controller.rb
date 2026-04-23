module Dev
  class ImpersonateController < ApplicationController
    prepend_before_action :verify_development_environment

    def create
      user = User.find(params[:id])
      bypass_sign_in(user)
      redirect_to(start_path)
    end

    private

      def verify_development_environment
        raise(ActionController::RoutingError, "Not Found") unless Rails.env.development?
      end
  end
end

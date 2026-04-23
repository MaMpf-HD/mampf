module Dev
  class BaseController < ApplicationController
    prepend_before_action :verify_development_environment

    private

      def verify_development_environment
        allowed = Rails.env.development? && request.local?

        raise(ActionController::RoutingError, "Not Found") unless allowed
      end
  end
end

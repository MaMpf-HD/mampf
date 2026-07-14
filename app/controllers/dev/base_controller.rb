module Dev
  class BaseController < ApplicationController
    prepend_before_action :verify_development_environment

    private

      def verify_development_environment
        # Don't use request.local? here since Docker uses 172. as IP range
        # for localhost, which is not considered local by Rails.
        allowed = Rails.env.local? && request.host == "localhost"

        raise(ActionController::RoutingError, "Not Found") unless allowed
      end
  end
end

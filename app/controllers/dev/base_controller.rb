module Dev
  class BaseController < ApplicationController
    LOCAL_DEV_HOSTS = ["localhost", "127.0.0.1", "::1"].freeze

    prepend_before_action :verify_development_environment

    private

      def verify_development_environment
        # Don't use request.local? here since Docker uses 172. as IP range
        # for localhost, which is not considered local by Rails.
        normalized_host = request.host.delete_prefix("[").delete_suffix("]")
        allowed = Rails.env.development? &&
                  normalized_host.in?(LOCAL_DEV_HOSTS)

        raise(ActionController::RoutingError, "Not Found") unless allowed
      end
  end
end

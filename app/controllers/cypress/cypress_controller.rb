module Cypress
  # Handles Cypress requests for interactive UI testing.
  #
  # The main purpose of this class is to send back errors as JSON object
  # to parse them in the Cypress test UI. This way, we can display the error
  # message and the stacktrace in the Cypress test.
  class CypressController < ApplicationController
    respond_to :json
    rescue_from Exception, with: :show_errors
    skip_before_action :authenticate_user!

    private

      # Returns the error as JSON such that it can be displayed in the Cypress test.
      def show_errors(exception)
        error = {
          error: "#{exception.class}: #{exception}",
          stacktrace: exception.backtrace.join("\n")
        }

        render json: error, status: :bad_request
      end
  end
end

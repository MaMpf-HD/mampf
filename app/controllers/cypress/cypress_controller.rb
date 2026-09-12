module Cypress
  # Handles Cypress requests for interactive UI testing.
  #
  # The main purpose of this class is to send back errors as JSON object
  # to parse them in the Cypress test UI. This way, we can display the error
  # message and the stacktrace in the Cypress test.
  #
  # The convention with the frontend is to return the status `created`
  # for successful requests and `bad_request` (or anything else) for failed requests.
  class CypressController < ApplicationController
    respond_to :json
    rescue_from Exception, with: :show_errors
    skip_before_action :authenticate_user!

    ATTEMPTS = 3

    private

      # A test's own page can still be finishing a request while the next test
      # asks the bridge for something, and Postgres picks one of the two to
      # abort. Nothing is half-done when it does, so the way out is to ask again.
      def retrying_deadlocks
        attempt = 0
        begin
          yield
        rescue ActiveRecord::Deadlocked
          attempt += 1
          raise if attempt >= ATTEMPTS

          sleep(0.1 * attempt)
          retry
        end
      end

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

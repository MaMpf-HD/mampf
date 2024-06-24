# Handles Cypress requests to create factories via FactoryBot.
# See the factorybot.js file in the Cypress support folder.
#
# It is inspired by this blog post by Tom Conroy:
# https://tbconroy.com/2018/04/07/creating-data-with-factorybot-for-rails-cypress-tests/
class FactoriesController < ApplicationController
  respond_to :json
  rescue_from Exception, with: :show_errors

  # Wrapper around FactoryBot.create to create a factory via a POST request.
  def create
    unless params["0"].is_a?(String)
      msg = "First argument must be a string indicating the factory name."
      msg += " But we got: '#{params["0"]}'"
      raise(ArgumentError, msg)
    end

    attributes = params_to_attributes(params.except(:controller, :action, :number))
    res = FactoryBot.create(*attributes)

    render json: res.to_json, status: :created
  end

  private

    def params_to_attributes(params)
      params.to_unsafe_hash.map do |_key, value|
        if value.is_a?(Hash)
          value.transform_keys(&:to_sym)
        elsif value.is_a?(String)
          value.to_sym
        else
          throw("Value is neither a hash nor a string: #{value}")
        end
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

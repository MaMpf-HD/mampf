module Cypress
  # Handles Cypress requests to create factories via FactoryBot.
  # See the factorybot.js file in the Cypress support folder.
  #
  # It is inspired by this blog post by Tom Conroy:
  # https://tbconroy.com/2018/04/07/creating-data-with-factorybot-for-rails-cypress-tests/
  class FactoriesController < CypressController
    # Wrapper around FactoryBot.create to create a factory via a POST request.
    def create
      unless params["0"].is_a?(String)
        msg = "First argument must be a string indicating the factory name."
        msg += " But we got: '#{params["0"]}'"
        raise(ArgumentError, msg)
      end

      attributes, should_validate = params_to_attributes(params.except(:controller, :action,
                                                                       :number))

      res = if should_validate
        FactoryBot.create(*attributes) # default case
      else
        FactoryBot.build(*attributes).tap { |instance| instance.save(validate: false) }
      end

      render json: res.to_json, status: :created
    end

    private

      def params_to_attributes(params)
        should_validate = true

        attributes = params.to_unsafe_hash.filter_map do |_key, value|
          if value.is_a?(Hash)
            if value.key?("validate")
              should_validate = (value["validate"] != "false")
            else
              value.transform_keys(&:to_sym)
            end
          elsif value.is_a?(String)
            value.to_sym
          else
            throw("Value is neither a hash nor a string: #{value}")
          end
        end

        return attributes, should_validate
      end
  end
end

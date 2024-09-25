module Cypress
  # Handles Cypress requests to create factories via FactoryBot.
  # See the factorybot.js file in the Cypress support folder.
  #
  # It is inspired by this blog post by Tom Conroy:
  # https://tbconroy.com/2018/04/07/creating-data-with-factorybot-for-rails-cypress-tests/
  class FactoriesController < CypressController
    # Creates an instance of the factory (via FactoryBot) and returns it as JSON.
    def create
      factory_name = validate_factory_name(params["0"])
      attributes, should_validate = params_to_attributes(
        params.except(:controller, :action, :number)
      )
      res = create_or_build_factory(attributes, should_validate)

      render json: res.as_json.merge({ factory_name: factory_name }), status: :created
    end

    # Calls the instance method on the instance created by FactoryBot.create().
    # Expects as arguments the factory name, the id of the instance,
    # the method name and the method arguments to be passed to the instance method.
    def call_instance_method
      factory_name = validate_factory_name(params["factory_name"]).capitalize
      id = params["instance_id"].to_i
      method_name = params["method_name"]
      method_args = params["method_args"]
      method_args, _validate = params_to_attributes(method_args) if method_args.present?

      # Find the instance
      begin
        instance = factory_name.constantize.find(id)
      rescue ActiveRecord::RecordNotFound
        result = { error: "Instance where you'd like to call '#{method_name}' on was not found" }
        return render json: result.to_json, status: :bad_request
      end

      # Call the instance method & return the result
      begin
        result = instance.send(method_name, *method_args)
        render json: result.to_json, status: :created
      rescue NoMethodError => _e
        result = { error: "Method '#{method_name}' not found on instance" }
        render json: result.to_json, status: :bad_request
      end
    end

    private

      def validate_factory_name(factory_name)
        return factory_name if factory_name.is_a?(String)

        msg = "First argument must be a string indicating the factory name."
        msg += " But we got: '#{factory_name}'"
        raise(ArgumentError, msg)
      end

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

      def transform_hash(value)
        value.transform_keys(&:to_sym).transform_values do |v|
          if v.is_a?(Hash) && v.keys.all? { |k| k.match?(/^\d+$/) }
            # Convert nested arrays to arrays of strings
            v.values.map(&:to_s)
          else
            v
          end
        end
      end

      def create_or_build_factory(attributes, should_validate)
        if should_validate
          FactoryBot.create(*attributes) # default case
        else
          FactoryBot.build(*attributes).tap { |instance| instance.save(validate: false) }
        end
      end
  end
end

module Cypress
  # Handles Playwright requests to create factories via FactoryBot.
  #
  # It is inspired by this blog post by Tom Conroy:
  # https://tbconroy.com/2018/04/07/creating-data-with-factorybot-for-rails-cypress-tests/
  class FactoriesPlaywrightController < CypressController
    # Creates an instance of the factory (via FactoryBot) and returns it as JSON.
    def create
      attributes, should_validate = to_attribute_list(params)
      data = create_class_instance_via_factorybot(attributes, should_validate)
      render json: data.as_json, status: :created
    end

    # Calls the instance method on the instance created by FactoryBot.create().
    # Expects as arguments the factory name, the id of the instance,
    # the method name and the method arguments to be passed to the instance method.
    def call_instance_method
      factory_name = validate_factory_name(params["factory_name"]).capitalize
      id = params["instance_id"].to_i
      method_name = params["method_name"]
      method_args = []

      # If user_id is present and valid, prepend the user object to method_args
      user_id_param = params["user_id"]
      if user_id_param.present?
        uid = user_id_param.to_i
        if uid.positive?
          begin
            user_obj = User.find(uid)
            method_args << user_obj
          rescue ActiveRecord::RecordNotFound
            result = { error: "User id #{uid} not found" }
            return render json: result.to_json, status: :bad_request
          end
        end
      end

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

        msg = "factory_name must be a string indicating the factory name."
        msg += " But we got: '#{factory_name}'"
        raise(ArgumentError, msg)
      end

      def to_attribute_list(params)
        attributes = []

        # Factory name
        attributes << validate_factory_name(params["factory_name"])

        # Factory traits
        attributes.concat(params[:traits].map(&:to_sym))

        # Factory arguments
        attributes << params[:args].to_unsafe_hash if params[:args].present?

        should_validate = true
        if params[:args].present? && params[:args].key?("validate")
          should_validate = params[:args]["validate"] != false
          attributes.last.delete("validate")
        end

        return attributes, should_validate
      end

      def create_class_instance_via_factorybot(attributes, should_validate)
        if should_validate
          FactoryBot.create(*attributes)
        else
          FactoryBot.build(*attributes).tap { |instance| instance.save(validate: false) }
        end
      end
  end
end

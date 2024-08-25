module Cypress
  # Handles Cypress requests to create factories via FactoryBot.
  # See the factorybot.js file in the Cypress support folder.
  #
  # It is inspired by this blog post by Tom Conroy:
  # https://tbconroy.com/2018/04/07/creating-data-with-factorybot-for-rails-cypress-tests/
  class FactoriesController < CypressController
    # Wrapper around FactoryBot.create to create a factory via a POST request.
    def create
      validate_factory_name(params["0"])

      attributes, should_validate = params_to_attributes(params.except(:controller, :action,
                                                                       :number))

      # Partition the attributes into valid attributes and instance methods
      attributes, instance_methods = partition_attributes(attributes)

      # Extract the values from the instance_methods hashes
      instance_methods = extract_instance_methods(instance_methods)

      res = create_or_build_factory(attributes, should_validate)

      instance_methods_results = evaluate_instance_methods(res, instance_methods)

      render json: res.as_json.merge(instance_methods_results), status: :created
    end

    private

      def validate_factory_name(factory_name)
        return if factory_name.is_a?(String)

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
              transform_hash(value)
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

      def partition_attributes(attributes)
        attributes.partition do |attr|
          !(attr.is_a?(Hash) && attr.keys == ["instance_methods"])
        end
      end

      def extract_instance_methods(instance_methods)
        instance_methods.flat_map { |hash| hash["instance_methods"] }
      end

      def create_or_build_factory(attributes, should_validate)
        if should_validate
          FactoryBot.create(*attributes) # default case
        else
          FactoryBot.build(*attributes).tap { |instance| instance.save(validate: false) }
        end
      end

      def evaluate_instance_methods(instance, methods)
        methods.index_with do |method_name|
          if instance.respond_to?(method_name)
            instance.send(method_name)
          else
            throw("Method not found: #{method_name}")
          end
        end
      end
  end
end

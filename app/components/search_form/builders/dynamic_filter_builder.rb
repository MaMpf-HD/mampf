module SearchForm
  module Builders
    class DynamicFilterBuilder
      def initialize(form_state, filter_name, config, **options)
        @form_state = form_state
        filter_class = "SearchForm::Filters::#{filter_name.camelize}Filter".constantize
        @filter = options.any? ? filter_class.new(**options) : filter_class.new
        @filter.form_state = form_state
        @config = config

        # Dynamically define the configuration methods
        define_configuration_methods
      end

      def build
        @filter
      end

      private

        def define_configuration_methods
          @config[:methods].each do |method_name|
            # Handle case where method_configs is missing or specific method config is missing
            method_config = @config.dig(:method_configs, method_name) || {}

            define_singleton_method(method_name) do |*args, **kwargs|
              execute_method_config(method_name, method_config, *args, **kwargs)
              self
            end
          end
        end

        def execute_method_config(method_name, method_config, *, **kwargs)
          # Default target_method to the method_name if not specified
          target_method = method_config[:target_method] || method_name

          # Determine arguments to pass
          if method_config[:default_args]
            merged_kwargs = method_config[:default_args].merge(kwargs)
            result = @filter.send(target_method, *, **merged_kwargs)
          else
            result = @filter.send(target_method, *, **kwargs)
          end

          # Handle special wrapper methods (like with_content for course filter)
          return unless method_config[:wrapper]

          @filter.send(method_config[:wrapper]) { result }
        end
    end
  end
end

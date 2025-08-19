module SearchForm
  module Controls
    # Base class for form control components that provides common functionality
    # for rendering, styling, and stimulus integration.
    class BaseControl < ViewComponent::Base
      attr_reader :form, :options, :stimulus_config

      def initialize(form:, stimulus: {}, **options)
        super()
        @form = form
        @stimulus_config = stimulus
        @options = options
      end

      # Determines the CSS class for the component's container element.
      # Can be customized by passing container_class: "your-class" to the component.
      def container_class
        options[:container_class] || default_container_class
      end

      # Default container class to use if not specified in options
      def default_container_class
        "form-check mb-2"
      end

      # Generate data attributes from stimulus config
      def data_attributes
        return options[:data] || {} if stimulus_config.empty?

        options[:data] || {}

        # Process stimulus config into data attributes
        # To be implemented by subclasses if needed
      end

      # HTML options for the form control
      def html_options
        result = {}

        result[:data] = data_attributes if data_attributes.any?
        result.merge(options.except(:container_class))
      end

      # Helper method to allow setting form after initialization
      def with_form(form)
        @form = form
        self
      end
    end
  end
end

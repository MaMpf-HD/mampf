module SearchForm
  module Controls
    # Base class for form control components that provides common functionality
    # for rendering, styling, and stimulus integration.
    class BaseControl < ViewComponent::Base
      attr_reader :form, :options, :stimulus_config, :dom_uid

      def initialize(form:, stimulus: {}, **options)
        super()
        @form = form
        @dom_uid = options.delete(:dom_uid) || SecureRandom.hex(6)
        @stimulus_config = stimulus
        @options = options
      end

      # The public ID for the <input> element itself.
      def element_id
        [form.object_name, base_id_string].compact.join("_")
      end

      # The public ID for the <label for="..."> attribute.
      # Rails prefixes this with the scope, so we just return the base.
      def label_for
        base_id_string
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

      private

        # A single, private method to construct the core, unique part of the ID.
        def base_id_string
          # It relies on the subclass to provide the specific parts.
          ([dom_uid] + id_parts.map { |p| p.to_s.strip }.reject(&:empty?)).join("_")
        end

        # This is the contract for subclasses. They must define what makes their ID unique.
        def id_parts
          raise(NotImplementedError, "#{self.class.name} must implement #id_parts")
        end
    end
  end
end

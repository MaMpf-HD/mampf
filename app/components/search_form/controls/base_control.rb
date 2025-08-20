module SearchForm
  module Controls
    class BaseControl < ViewComponent::Base
      attr_reader :form_state, :options, :stimulus_config

      def initialize(form_state:, stimulus: {}, **options)
        super()
        @form_state = form_state
        @stimulus_config = stimulus
        @options = options
      end

      delegate :form, to: :form_state
      delegate :context, to: :form_state

      # The public ID for the <input> element itself
      def element_id
        form_state.element_id_for(*id_parts)
      end

      # The public ID for the <label for="..."> attribute
      def label_for
        form_state.label_for(*id_parts)
      end

      # Keep all your existing methods unchanged
      def container_class
        options[:container_class] || default_container_class
      end

      def default_container_class
        "form-check mb-2"
      end

      def data_attributes
        return options[:data] || {} if stimulus_config.empty?

        options[:data] || {}
      end

      def html_options
        result = {}
        result[:data] = data_attributes if data_attributes.any?
        result.merge(options.except(:container_class))
      end

      def with_form(form)
        form_state.with_form(form)
        self
      end

      private

        def id_parts
          raise(NotImplementedError, "#{self.class.name} must implement #id_parts")
        end
    end
  end
end

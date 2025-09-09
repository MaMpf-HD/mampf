module SearchForm
  module Fields
    # Renders a standard HTML `<input type="text">` field. This is a general-purpose
    # component for free-text input, styled with the standard Bootstrap class.
    class TextField < ViewComponent::Base
      attr_reader :field_data

      def initialize(name:, label:, form_state:, **options)
        super()

        # Create field data object
        @field_data = FieldData.new(
          name: name,
          label: label,
          help_text: options[:help_text],
          form_state: form_state,
          options: options.dup
        )

        # Override the default_field_classes method to provide Bootstrap classes
        field_data.define_singleton_method(:default_field_classes) do
          ["form-control"]
        end

        # Extract and update field classes
        field_data.extract_and_update_field_classes!(options)
      end

      # Delegate common methods to field_data
      delegate :name, :label, :help_text, :form, :container_class, :show_help_text?,
               :show_content?, :content, :options, :html, to: :field_data

      # Form state interface for SearchForm auto-injection
      delegate :form_state, to: :field_data
      
      def form_state=(new_form_state)
        field_data.form_state = new_form_state
      end

      def with_form(form)
        field_data.form_state.with_form(form)
        self
      end

      def with_content(&block)
        field_data.with_content(&block)
        self
      end

      def before_render
        raise("Form not set for #{self.class.name}. Call with_form before rendering.") unless form
      end
    end
  end
end
module SearchForm
  module Fields
    # Renders a standard HTML `<input type="text">` field. This is a general-purpose
    # component for free-text input, styled with the standard Bootstrap class.
    class TextField < ViewComponent::Base
      attr_reader :field_data

      # Initializes a new TextField.
      #
      # This class does not introduce any new parameters beyond the base field functionality.
      # It primarily uses the options for styling, such as `:placeholder`, `:class`, and data attributes.
      #
      # @param name [Symbol] The name of the field.
      # @param label [String] The label text for the field.
      # @param form_state [FormState] The form state object for form integration.
      # @param options [Hash] A hash of options for styling and attributes.
      def initialize(name:, label:, form_state:, **options)
        super()

        # Process options
        processed_options = options.dup

        # Create field data object
        @field_data = FieldData.new(
          name: name,
          label: label,
          help_text: options[:help_text],
          form_state: form_state,
          options: processed_options
        )

        # Override the default_field_classes method to provide Bootstrap classes
        field_data.define_singleton_method(:default_field_classes) do
          ["form-control"]
        end

        # Extract and update field classes (must happen after defining default_field_classes)
        field_data.extract_and_update_field_classes!(processed_options)
      end

      # Delegate common methods to field_data
      delegate :name, :label, :help_text, :form, :container_class, :show_help_text?,
               :show_content?, :content, :options, :html, to: :field_data

      # Add form_state interface for SearchForm auto-injection
      def form_state
        field_data.form_state
      end

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

      # Provides the default CSS class for the `<input>` element.
      #
      # @return [Array<String>] An array containing the Bootstrap "form-control" class.
      def default_field_classes
        ["form-control"] # Bootstrap form-control class
      end

      # A ViewComponent lifecycle callback that runs before rendering.
      # Ensures that the form builder has been set, preventing runtime errors.
      def before_render
        raise("Form not set for #{self.class.name}. Call with_form before rendering.") unless form
      end
    end
  end
end
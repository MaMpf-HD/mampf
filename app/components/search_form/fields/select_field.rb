module SearchForm
  module Fields
    # Renders a standard HTML `<select>` dropdown field. This component provides
    # a simple, non-JavaScript-enhanced dropdown menu, suitable for basic
    # selection tasks. It uses the standard Bootstrap class for styling.
    class SelectField < ViewComponent::Base
      attr_reader :collection, :field_data

      # Initializes a new SelectField.
      #
      # @param name [Symbol] The name of the field.
      # @param label [String] The label text for the field.
      # @param collection [Array] The collection of options for the select tag,
      #   in a format suitable for the Rails `form.select` helper.
      # @param options [Hash] A hash of options passed to the base `Field`. This
      #   class specifically uses:
      #   - `:prompt` (String, Boolean) - The prompt text. Defaults to `false` (no prompt),
      #     as inherited from the base `Field`.
      #   - `:selected` (Object) - The pre-selected value. There is no default.
      def initialize(name:, label:, collection:, form_state:, **options)
        super()
        @collection = collection

        # Process options to extract prompt and selected values
        processed_options = process_options(options)
        
        # Create field data object
        @field_data = FieldData.new(
          name: name,
          label: label,
          help_text: options[:help_text],
          form_state: form_state,
          options: processed_options,
          prompt: processed_options[:prompt],
          selected: processed_options[:selected]
        )

        # Override the default_field_classes method to provide Bootstrap classes
        field_data.define_singleton_method(:default_field_classes) do
          ["form-select"]
        end

        # Extract and update field classes (must happen after defining default_field_classes)
        field_data.extract_and_update_field_classes!(processed_options)
      end

      # Delegate common methods to field_data
      delegate :name, :label, :help_text, :form, :container_class, :show_help_text?,
               :show_content?, :html, :content, :prompt, :selected, to: :field_data

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

      # Delegates to the HtmlBuilder to get the options hash for the `form.select`
      # helper (the 3rd parameter), which includes `:prompt` and `:selected`.
      delegate :select_tag_options, to: :html

      # Provides the default CSS class for the `<select>` element.
      #
      # @return [Array<String>] An array containing the Bootstrap "form-select" class.
      def default_field_classes
        ["form-select"] # Bootstrap form-select class
      end

      # A ViewComponent lifecycle callback that runs before rendering.
      # Ensures that the form builder has been set, preventing runtime errors.
      def before_render
        raise("Form not set for #{self.class.name}. Call with_form before rendering.") unless form
      end

      private

        # Process options to set defaults for SelectField
        def process_options(options)
          # Set default prompt to false (no prompt) unless specified
          options.reverse_merge(
            prompt: default_prompt
          )
        end

        # Hook for subclasses to define their default prompt behavior (e.g., for select fields).
        #
        # @return [Boolean] Defaults to false, indicating no prompt.
        def default_prompt
          false
        end
    end
  end
end
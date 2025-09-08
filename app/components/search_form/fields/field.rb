module SearchForm
  # The Fields module contains all the individual field components that can be
  # rendered within a SearchForm. This includes a base `Field` class and concrete
  # implementations like `TextField`, `SelectField`, etc.
  module Fields
    # Field is an abstract base class for all form field components. It provides
    # a shared foundation for common attributes, layout options, and integration
    # with the form's state and helper services.
    #
    # Its primary responsibilities are:
    # - Holding common state for a field (name, label, options).
    # - Providing a consistent interface for layout (`container_class`, `field_class`).
    # - Delegating complex CSS and HTML attribute generation to service objects
    #   (`CssManager` and `HtmlBuilder`).
    # - Integrating with `FormState` to access the form builder and context.
    # - Defining a contract for subclasses to implement (`default_field_classes`, etc.).
    class Field < ViewComponent::Base
      attr_reader :name, :label, :field_class, :help_text, :options,
                  :content, :css, :html, :prompt
      attr_accessor :form_state

      # Initializes a new Field instance.
      #
      # @param name [Symbol] The name of the field.
      # @param label [String] The label text for the field.
      # @param options [Hash] A hash of options for layout and HTML attributes.
      #   This includes:
      #   - **Layout & Styling:**
      #     - `:class` (String) - The standard way to pass custom CSS classes, just like
      #       with Rails helpers. This is the recommended option for users of the component.
      #     - `:field_class` (String) - Used internally by field subclasses to add their
      #       own specific classes (e.g., "form-control"). Both `:class` and `:field_class`
      #       are combined in the final output. Defaults to `""`.
      #     - `:container_class` (String) - Overrides CSS for the wrapping `div`.
      #       Defaults to `"col-6 col-lg-3 mb-3 form-field-group"`.
      #     - `:help_text` (String) - Text displayed in a helpdesk beside the label. No default.
      #   - **Behavior & Accessibility:**
      #     - `:prompt` (String, Boolean) - The prompt text for select-style fields.
      #       Defaults to `false` (no prompt).
      #     - `:selected` (Object) - The pre-selected value for select-style fields. No default.
      #     - `:required` (Boolean) - Adds `aria-required="true"` for accessibility. No default.
      #   - **General Passthrough:**
      #     - Any other key-value pairs (e.g., `:placeholder`, `data: { ... }`) are
      #       passed through as HTML attributes to the final input/select element.
      def initialize(name:, label:, **options)
        super()
        @name = name
        @label = label
        @form_state = options.delete(:form_state)

        @provided_container_class = options.delete(:container_class)
        @field_class = options.delete(:field_class) || ""
        @help_text = options.delete(:help_text)
        @prompt = options.delete(:prompt) { default_prompt }
        @options = process_options(options)

        # Make services accessible as public APIs
        @css = Services::CssManager.new(self)
        @html = Services::HtmlBuilder.new(self)
      end

      # Delegate form access to form_state
      delegate :form, to: :form_state

      # Delegate context access to form_state
      delegate :context, to: :form_state

      # Injects the form builder into the `form_state` object.
      # This is a crucial step in the render lifecycle, called by the parent form.
      #
      # @param form [ActionView::Helpers::FormBuilder] The form builder instance.
      # @return [self] Returns itself to allow for method chaining.
      def with_form(form)
        form_state.with_form(form)
        self
      end

      # Captures a content block to be rendered within the field's template.
      #
      # @param &block [Proc] The content block.
      # @return [self] Returns itself to allow for method chaining.
      def with_content(&block)
        @content = block if block
        self
      end

      # Lazily resolve container class so subclasses can override defaults
      def container_class
        @provided_container_class.presence || default_container_class
      end

      # Default wrapper class; children can override
      def default_container_class
        "col-6 col-lg-3 mb-3 form-field-group"
      end

      # Common conditional methods
      # @return [Boolean] True if help text is present.
      def show_help_text?
        help_text.present?
      end

      # @return [Boolean] True if a content block was provided.
      def show_content?
        content.present?
      end

      # A ViewComponent lifecycle callback that runs before rendering.
      # Ensures that the form builder has been set, preventing runtime errors.
      def before_render
        raise("Form not set for #{self.class.name}. Call with_form before rendering.") unless form
      end

      # Hook for subclasses to provide an array of default CSS classes for the field element.
      #
      # @return [Array<String>] An array of CSS class names.
      def default_field_classes
        []
      end

      # Provides access to the `:selected` value from the options hash.
      #
      # @return [Object, nil] The selected value for the field.
      def selected
        options[:selected] # Method name now matches the option key
      end

      # Hook for subclasses to define their default prompt behavior (e.g., for select fields).
      #
      # @return [Boolean] Defaults to false, indicating no prompt.
      def default_prompt
        false
      end

      protected

        # A helper for subclasses to call in their initializer. It uses the CssManager
        # to extract CSS classes from the options hash and merges them with the
        # existing `field_class` attribute.
        #
        # @param options [Hash] The options hash to extract classes from.
        # @return [void]
        def extract_and_update_field_classes!(options)
          extracted_classes = css.extract_field_classes(options)
          @field_class = [field_class, extracted_classes].compact.join(" ").strip
        end

        # A hook for subclasses to process or modify the options hash after standard
        # options have been extracted.
        #
        # @param options [Hash] The incoming options hash.
        # @return [Hash] The processed options hash.
        def process_options(options)
          options
        end
    end
  end
end

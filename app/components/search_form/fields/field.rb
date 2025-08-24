# Search Form Fields Module
#
# This module contains field components that represent individual form inputs
# within the SearchForm system. Each field type provides specialized behavior
# while inheriting common functionality from the base Field class.
#
# Field architecture:
# - Field: Base class with common form field functionality
# - TextField: Single-line text input
# - SelectField: Dropdown selection
# - MultiSelectField: Multiple selection dropdown
# - CheckboxField: Single checkbox input
# - SubmitField: Form submission button
#
# All fields integrate with:
# - FormState for dependency injection and state management
# - Service objects for HTML generation and CSS management
# - ViewComponent architecture for Rails component rendering

module SearchForm
  module Fields
    # Base field class for all search form input types
    #
    # This class provides the foundational behavior that all field types inherit.
    # It handles common concerns like form state management, CSS classes,
    # help text, and integration with service objects.
    #
    # @param name [String, Symbol] The field name used for form parameters
    # @param label [String] Display label for the field
    # @param container_class [String] CSS classes for the field container
    # @param field_class [String] CSS classes for the input element
    # @param help_text [String] Optional help text displayed below the field
    # @param prompt [String] Placeholder or prompt text for the field
    # @param options [Hash] Additional options passed to the field
    #
    # @example Basic field usage
    #   field = Field.new(
    #     name: :search_term,
    #     label: "Search Term",
    #     help_text: "Enter keywords to search for"
    #   )
    #   field.form_state = form_state
    #
    # @example Field with custom CSS
    #   field = Field.new(
    #     name: :title,
    #     label: "Title",
    #     container_class: "col-md-6",
    #     field_class: "form-control-lg"
    #   )
    class Field < ViewComponent::Base
      attr_reader :name, :label, :container_class, :field_class, :help_text, :options,
                  :content, :css, :html, :prompt
      attr_accessor :form_state

      def initialize(name:, label:, **options)
        super()
        @name = name
        @label = label

        # Extract layout options with defaults
        @container_class = options.delete(:container_class) ||
                           "col-6 col-lg-3 mb-3 form-field-group"
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

      delegate :context, to: :form_state

      def with_form(form)
        form_state.with_form(form)
        self
      end

      def with_content(&block)
        @content = block if block
        self
      end

      # Common conditional methods
      def show_help_text?
        help_text.present?
      end

      def show_content?
        content.present?
      end

      def before_render
        raise("Form not set for #{self.class.name}. Call with_form before rendering.") unless form
      end

      # To be overridden by subclasses
      def default_field_classes
        []
      end

      def selected
        options[:selected] # Method name now matches the option key
      end

      # Override in subclasses to set appropriate defaults
      def default_prompt
        false
      end

      protected

        # Call this in subclass initialize after super to extract field classes
        def extract_and_update_field_classes!(options)
          extracted_classes = css.extract_field_classes(options)
          @field_class = [field_class, extracted_classes].compact.join(" ").strip
        end

        def process_options(options)
          options
        end
    end
  end
end

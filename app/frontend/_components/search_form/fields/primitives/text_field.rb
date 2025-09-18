module SearchForm
  module Fields
    module Primitives
      # Standard HTML `<input type="text">` field for free-text input.
      #
      # The component supports all standard HTML input attributes including
      # placeholder, maxlength, pattern, and data attributes.
      #
      # @example Basic text field
      #   TextField.new(
      #     name: :search_query,
      #     label: "Search",
      #     form_state: form_state
      #   )
      #
      # @example Text field with placeholder and validation
      #   TextField.new(
      #     name: :email,
      #     label: "Email Address",
      #     form_state: form_state,
      #     placeholder: "Enter your email",
      #     required: true,
      #     pattern: "[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$"
      #   )
      class TextField < ViewComponent::Base
        include Fields::Mixins::PrimitiveFieldMixin
        attr_reader :field_data

        # Initializes a new TextField component.
        #
        # This component uses standard Bootstrap form-control styling and supports
        # all HTML input attributes through the options hash.
        #
        # @param name [Symbol] The field name for form binding and ID generation
        # @param label [String] The human-readable label text
        # @param form_state [FormState] The form state object for context
        # @param options [Hash] Additional HTML attributes and configuration including:
        #   - placeholder: Placeholder text for the input
        #   - maxlength: Maximum number of characters allowed
        #   - pattern: HTML5 validation pattern (regex)
        #   - required: Whether the field is required
        #   - disabled: Whether the field is disabled
        #   - readonly: Whether the field is read-only
        #   - data: Hash of data attributes for client-side behavior
        def initialize(name:, label:, form_state:, **)
          super()

          initialize_field_data(
            name: name,
            label: label,
            form_state: form_state,
            default_classes: ["form-control"], # Bootstrap text input styling
            **
          )
        end

        # Provides access to the HTML builder service for generating form attributes.
        # This enables the template to call methods like `html.field_html_options`.
        #
        # @return [Services::HtmlBuilder] The HTML builder service instance
        delegate :html, to: :field_data
      end
    end
  end
end

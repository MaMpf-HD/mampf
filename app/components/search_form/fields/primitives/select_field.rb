module SearchForm
  module Fields
    module Primitives
      # Renders a standard HTML `<select>` dropdown field. This component provides
      # a simple, non-JavaScript-enhanced dropdown menu, suitable for basic
      # selection tasks. It uses Bootstrap form-select styling.
      #
      # The component supports all standard select options including prompts,
      # pre-selected values, and disabled states. It's designed for straightforward
      # single-selection scenarios without client-side enhancements.
      #
      # @example Basic select field
      #   SelectField.new(
      #     name: :category,
      #     label: "Category",
      #     collection: [["Option 1", 1], ["Option 2", 2]],
      #     form_state: form_state
      #   )
      #
      # @example Select field with prompt and pre-selection
      #   SelectField.new(
      #     name: :status,
      #     label: "Status",
      #     collection: status_options,
      #     form_state: form_state,
      #     prompt: "Choose a status...",
      #     selected: "active"
      #   )
      class SelectField < ViewComponent::Base
        include FieldMixins

        attr_reader :collection, :field_data

        # Initializes a new SelectField component.
        #
        # @param name [Symbol] The field name for form binding and ID generation
        # @param label [String] The human-readable label text
        # @param collection [Array] Array of options in Rails select helper format
        #   (e.g., [["Display Text", "value"], ...] or ["option1", "option2"])
        # @param form_state [FormState] The form state object for context
        # @param options [Hash] Additional configuration options including:
        #   - prompt: Prompt text or boolean (default: false - no prompt)
        #   - selected: Pre-selected value
        #   - disabled: Whether the select is disabled
        #   - required: Whether the field is required
        #   - multiple: Whether to allow multiple selections (rarely used for SelectField)
        def initialize(name:, label:, collection:, form_state:, **options)
          super()
          @collection = collection

          # Process options with defaults appropriate for basic select fields
          processed_options = process_select_options(options)

          initialize_field_data(
            name: name,
            label: label,
            form_state: form_state,
            default_classes: ["form-select"], # Bootstrap select styling
            prompt: processed_options[:prompt],
            selected: processed_options[:selected],
            **processed_options
          )
        end

        # Additional delegations specific to select fields
        delegate :html, :prompt, :selected, to: :field_data

        # Delegates to the HtmlBuilder to get the options hash for Rails' `form.select`
        # helper (the 3rd parameter), which includes `:prompt` and `:selected`.
        #
        # @return [Hash] Options hash for Rails select helper
        delegate :select_tag_options, to: :html

        private

          # Processes initialization options with defaults appropriate for select fields.
          # Basic select fields typically don't show prompts by default, unlike
          # multi-select fields which benefit from user guidance.
          #
          # @param opts [Hash] The raw options passed to initialize
          # @return [Hash] Processed options with defaults applied
          def process_select_options(opts)
            opts.reverse_merge(
              prompt: false # No prompt by default for simple selects
            )
          end
      end
    end
  end
end

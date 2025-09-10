module SearchForm
  module Fields
    module Primitives
      # Renders a multi-select field, typically enhanced with a JavaScript library
      # like Selectize. This component focuses on rendering the select element itself,
      # with any associated controls (checkboxes, radio buttons) being handled by
      # parent filter components through composition.
      #
      # The component provides extensive customization through options and supports
      # Stimulus.js data attributes for client-side behavior.
      #
      # @example Basic multi-select
      #   MultiSelectField.new(
      #     name: :categories,
      #     label: "Categories",
      #     collection: [["Option 1", 1], ["Option 2", 2]],
      #     form_state: form_state
      #   )
      #
      # @example Multi-select with custom options
      #   MultiSelectField.new(
      #     name: :tags,
      #     label: "Tags",
      #     collection: tag_options,
      #     form_state: form_state,
      #     multiple: true,
      #     prompt: "Choose tags...",
      #     selected: [1, 3]
      #   )
      class MultiSelectField < ViewComponent::Base
        include PrimitivesMixins

        attr_reader :collection, :data_builder, :field_data

        # Initializes a new MultiSelectField component.
        #
        # @param name [Symbol] The field name for form binding and ID generation
        # @param label [String] The human-readable label text
        # @param collection [Array] Array of options for the select element (Rails format)
        # @param form_state [FormState] The form state object for context
        # @param options [Hash] Additional configuration options including:
        #   - multiple: Whether to allow multiple selections (default: true)
        #   - disabled: Whether the field is disabled (default: true)
        #   - required: Whether the field is required (default: true)
        #   - prompt: Prompt text for the select (default: true)
        #   - selected: Pre-selected values
        def initialize(name:, label:, collection:, form_state:, **options)
          super()
          @collection = collection

          # Process options with sensible defaults for multi-select
          processed_options = process_options(options)

          initialize_field_data(
            name: name,
            label: label,
            form_state: form_state,
            default_classes: ["selectize"], # Selectize CSS class for JavaScript enhancement
            **processed_options
          )

          # Initialize service objects for data attribute building
          @data_builder = Services::DataAttributesBuilder.new(field_data)
        end

        # Additional delegations specific to select fields
        delegate :html, :prompt, :multiple, :disabled, :required, :selected, to: :field_data

        # Builds HTML options for the select element with data attributes.
        # Combines standard field HTML options with select-specific data attributes
        # required for Stimulus.js controllers and Selectize initialization.
        #
        # @param additional_options [Hash] Extra options to merge into the final hash
        # @return [Hash] Complete HTML options hash for the select element
        def field_html_options(additional_options = {})
          html.field_html_options(additional_options.merge(data: data_builder.select_data_attributes))
        end

        # Delegates to the HTML builder for Rails select helper options.
        # These are the options passed as the third argument to Rails' select helper.
        #
        # @return [Hash] Options hash for Rails select helper (prompt, selected, etc.)
        delegate :select_tag_options, to: :html

        private

          # Processes initialization options with defaults appropriate for multi-select fields.
          # Multi-select fields typically allow multiple selections, are interactive,
          # and show a prompt to guide user selection.
          #
          # @param opts [Hash] The raw options passed to initialize
          # @return [Hash] Processed options with defaults applied
          def process_options(opts)
            opts.reverse_merge(
              multiple: true,    # Allow multiple selections by default
              disabled: true,    # Interactive by default
              required: true,    # Required by default
              prompt: true       # Show prompt by default
            )
          end
      end
    end
  end
end

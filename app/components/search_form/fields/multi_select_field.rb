module SearchForm
  module Fields
    # Renders a multi-select field, typically enhanced with a JavaScript library
    # like Selectize.
    class MultiSelectField < Field
      attr_reader :collection, :data_builder

      # Initializes a new MultiSelectField.
      #
      # @param name [Symbol] The name of the field.
      # @param label [String] The label text for the field.
      # @param collection [Array] The collection of options for the select tag.
      # @param options [Hash] A hash of options passed to the base `Field`. This class
      #   uses the `process_options` method to set its own defaults:
      #   - `:multiple` defaults to `true`.
      #   - `:disabled` defaults to `true` (to be controlled by external components).
      #   - `:required` defaults to `true`.
      #   - `:prompt` defaults to `true` (overriding the base `Field` behavior).
      #   - `:selected` has no default.
      #   These can be overridden by passing them explicitly in the options hash.
      def initialize(name:, label:, collection:, **options)
        @collection = collection

        super(
          name: name,
          label: label,
          **options
        )

        extract_and_update_field_classes!(options)

        # Initialize service objects
        @data_builder = Services::DataAttributesBuilder.new(self)
      end

      # Builds the HTML options hash for the `<select>` tag itself (the 4th
      # parameter to `form.select`). It merges in the necessary Stimulus
      # data attributes for toggling behavior.
      #
      # @param additional_options [Hash] Extra options to merge.
      # @return [Hash] The final HTML options hash.
      def field_html_options(additional_options = {})
        html.field_html_options(additional_options.merge(data: data_builder.select_data_attributes))
      end

      # Delegates to the HtmlBuilder to get the options hash for the `form.select`
      # helper (the 3rd parameter), which includes `:prompt` and `:selected`.
      delegate :select_tag_options, to: :html

      # Overrides the base `Field` method to default to having a prompt.
      #
      # @return [Boolean] Always `true`.
      def default_prompt
        true # Multi-select fields should have prompts by default
      end

      # Provides default CSS classes for the `<select>` element.
      #
      # @return [Array<String>] An array containing the "selectize" class.
      def default_field_classes
        ["selectize"] # Base selectize class for multi-select
      end

      private

        # Merges default options required for a multi-select field.
        # These are reverse-merged, so they can be overridden by the user.
        def process_options(opts)
          opts.reverse_merge(
            multiple: true,
            disabled: true,
            required: true
          )
        end
    end
  end
end

module SearchForm
  module Fields
    # Renders a standard HTML `<select>` dropdown field. This component provides
    # a simple, non-JavaScript-enhanced dropdown menu, suitable for basic
    # selection tasks. It uses the standard Bootstrap class for styling.
    class SelectField < Field
      attr_reader :collection

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
      def initialize(name:, label:, collection:, **options)
        @collection = collection

        super(
          name: name,
          label: label,
          **options
        )

        extract_and_update_field_classes!(options)
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
    end
  end
end

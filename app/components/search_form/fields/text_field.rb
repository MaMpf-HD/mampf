module SearchForm
  module Fields
    # Renders a standard HTML `<input type="text">` field. This is a general-purpose
    # component for free-text input, styled with the standard Bootstrap class.
    class TextField < Field
      # Initializes a new TextField.
      #
      # This class does not introduce any new parameters beyond the base `Field`.
      # It primarily uses the options inherited from the parent class, such as
      # `:placeholder`, `:class`, and `data` attributes.
      #
      # @param name [Symbol] The name of the field.
      # @param label [String] The label text for the field.
      # @param options [Hash] A hash of options passed to the base `Field`.
      def initialize(name:, label:, **options)
        super

        extract_and_update_field_classes!(options)
      end

      # Provides the default CSS class for the `<input>` element.
      #
      # @return [Array<String>] An array containing the Bootstrap "form-control" class.
      def default_field_classes
        ["form-control"] # Bootstrap form-control class
      end
    end
  end
end

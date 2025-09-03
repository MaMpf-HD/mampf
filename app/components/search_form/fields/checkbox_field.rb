module SearchForm
  module Fields
    # Renders a single checkbox control within the standard field layout.
    # This component acts as a wrapper, delegating the actual checkbox rendering
    # to a `Controls::Checkbox` instance while providing the surrounding `div`
    # and label structure common to all fields.
    class CheckboxField < Field
      attr_reader :checked

      # Initializes a new CheckboxField.
      #
      # @param name [Symbol] The name of the field.
      # @param label [String] The label text for the field.
      # @param checked [Boolean] The initial checked state of the checkbox. Defaults to `false`.
      # @param options [Hash] A hash of options passed to the base `Field` class.
      def initialize(name:, label:, checked: false, **options)
        @checked = checked

        super(
          name: name,
          label: label,
          **options
        )

        extract_and_update_field_classes!(options)
      end

      # Instantiates and returns the underlying `Controls::Checkbox` component
      # that will be rendered inside the field's wrapper.
      #
      # @return [SearchForm::Controls::Checkbox] The checkbox control component.
      def checkbox_control
        @checkbox_control ||= Controls::Checkbox.new(
          form_state: form_state,
          name: name,
          label: label,
          checked: checked,
          help_text: help_text,
          container_class: "form-check mb-2" # Match the existing checkbox styling
        )
      end

      # Overrides the base method to provide no default classes.
      # The styling is handled by the inner `Controls::Checkbox` component,
      # so the wrapping field element itself does not require any specific classes.
      #
      # @return [Array] An empty array.
      def default_field_classes
        []
      end
    end
  end
end

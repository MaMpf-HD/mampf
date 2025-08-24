module SearchForm
  module Fields
    # Checkbox field component for boolean input
    #
    # This field type renders a single checkbox input for boolean values.
    # It's used for yes/no options, feature toggles, or boolean filters
    # in search forms.
    #
    # Features:
    # - Boolean state management
    # - Integration with checkbox control component
    # - Support for checked/unchecked initial states
    # - Custom styling through container and field classes
    #
    # @param checked [Boolean] Initial checked state of the checkbox
    #
    # @example Basic checkbox field
    #   add_checkbox_field(
    #     name: :include_archived,
    #     label: "Include archived items",
    #     checked: false
    #   )
    #
    # @example Checkbox with help text
    #   add_checkbox_field(
    #     name: :send_notifications,
    #     label: "Send email notifications",
    #     checked: true,
    #     help_text: "You will receive updates about search results"
    #   )
    class CheckboxField < Field
      attr_reader :checked

      def initialize(name:, label:, checked: false, **options)
        @checked = checked

        super(
          name: name,
          label: label,
          **options
        )

        extract_and_update_field_classes!(options)
      end

      # We'll render the checkbox control inside our field wrapper
      def checkbox_control
        @checkbox_control ||= Controls::Checkbox.new(
          form_state: form_state,
          name: name,
          label: label,
          checked: checked,
          container_class: "form-check mb-2" # Match the existing checkbox styling
        )
      end

      def default_field_classes
        [] # Checkbox doesn't need field-level classes since the control handles its own styling
      end
    end
  end
end

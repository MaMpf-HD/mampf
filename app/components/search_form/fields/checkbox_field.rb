module SearchForm
  module Fields
    class CheckboxField < Field
      attr_reader :checked

      def initialize(name:, label:, checked: false, **options)
        @checked = checked

        super(
          name: name,
          label: label,
          **options
        )

        # Extract and update field classes after initialization
        extracted_classes = css.extract_field_classes(options)
        @field_class = [field_class, extracted_classes].compact.join(" ").strip
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

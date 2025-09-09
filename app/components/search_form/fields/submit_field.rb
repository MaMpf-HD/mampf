module SearchForm
  module Fields
    # Renders a submit button for the search form. This component provides
    # a styled button and flexible wrapper divs for layout control.
    class SubmitField < ViewComponent::Base
      attr_reader :button_class, :inner_class, :field_data

      # Initializes a new SubmitField.
      #
      # Unlike other fields, this component does not take a `name` parameter, as
      # it corresponds to the form's submit action.
      #
      # @param label [String] The text displayed on the button.
      #   Defaults to the I18n translation for "basics.search".
      # @param button_class [String] The CSS class(es) for the `<input type="submit">` element.
      #   Defaults to `"btn btn-primary"`.
      # @param container_class [String] The CSS class(es) for the main wrapping `div`.
      #   Defaults to `"row mb-3"`.
      # @param inner_class [String] The CSS class(es) for an optional inner `div` that
      #   wraps the button, useful for alignment. Defaults to `"col-12 text-center"`.
      # @param options [Hash] A hash of options passed to the field data.
      def initialize(label: nil, button_class: "btn btn-primary",
                     container_class: "row mb-3", inner_class: "col-12 text-center", 
                     form_state: nil, **options)
        super()
        @button_class = button_class
        @inner_class = inner_class

        # Set custom container class in options
        processed_options = options.merge(container_class: container_class)

        # Create field data object with submit as the name
        @field_data = FieldData.new(
          name: :submit,
          label: label || I18n.t("basics.search"),
          form_state: form_state,
          options: processed_options
        )

        # Override the default_field_classes method (submit buttons don't have field classes)
        field_data.define_singleton_method(:default_field_classes) do
          []
        end

        # Extract and update field classes
        field_data.extract_and_update_field_classes!(processed_options)
      end

      # Delegate common methods to field_data
      delegate :name, :label, :form, :container_class, to: :field_data

      # Add form_state interface for SearchForm auto-injection
      def form_state
        field_data.form_state
      end

      def form_state=(new_form_state)
        field_data.form_state = new_form_state
      end

      def with_form(form)
        field_data.form_state.with_form(form)
        self
      end

      def with_content(&block)
        field_data.with_content(&block)
        self
      end

      # Overrides the base method to provide no default classes.
      # Submit buttons don't use field-level CSS classes.
      def default_field_classes
        []
      end

      # A ViewComponent lifecycle callback that runs before rendering.
      # Ensures that the form builder has been set, preventing runtime errors.
      def before_render
        raise("Form not set for #{self.class.name}. Call with_form before rendering.") unless form
      end
    end
  end
end
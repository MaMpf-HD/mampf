module SearchForm
  module Fields
    # Renders a submit button for the search form. This component provides
    # a styled button and flexible wrapper divs for layout control.
    class SubmitField < Field
      attr_reader :button_class, :inner_class

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
      # @param options [Hash] A hash of options passed to the base `Field`, though
      #   they are generally not used by this component.
      def initialize(label: nil, button_class: "btn btn-primary",
                     container_class: "row mb-3", inner_class: "col-12 text-center", **)
        super(name: :submit, label: label || I18n.t("basics.search"),
              container_class: container_class, **)
        @button_class = button_class
        @inner_class = inner_class
      end
    end
  end
end

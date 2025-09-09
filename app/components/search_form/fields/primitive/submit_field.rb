module SearchForm
  module Fields
    # Renders a submit button for the search form. This component provides
    # a styled button with flexible wrapper divs for layout control.
    #
    # Unlike other field components, this doesn't represent a data input but
    # rather the form submission action. It supports custom button styling,
    # container layouts, and internationalized button text.
    #
    # @example Basic submit button
    #   SubmitField.new(form_state: form_state)
    #
    # @example Custom submit button with styling
    #   SubmitField.new(
    #     label: "Find Results",
    #     button_class: "btn btn-success btn-lg",
    #     container_class: "row mt-4",
    #     inner_class: "col-12 text-end",
    #     form_state: form_state
    #   )
    class SubmitField < ViewComponent::Base
      include FieldMixins

      attr_reader :button_class, :inner_class, :field_data

      # Initializes a new SubmitField component.
      #
      # Unlike other fields, this component uses `:submit` as a fixed name since
      # it represents the form's submit action rather than a data field.
      #
      # @param label [String, nil] The text displayed on the button.
      #   Defaults to the I18n translation for "basics.search"
      # @param button_class [String] The CSS class(es) for the `<input type="submit">` element
      # @param container_class [String] The CSS class(es) for the main wrapping `div`
      # @param inner_class [String] The CSS class(es) for the inner alignment `div`
      # @param form_state [FormState] The form state object for context
      # @param options [Hash] Additional HTML attributes and configuration
      def initialize(label: nil, button_class: "btn btn-primary",
                     container_class: "row mb-3", inner_class: "col-12 text-center",
                     form_state: nil, **options)
        super()
        @button_class = button_class
        @inner_class = inner_class

        processed_options = options.merge(container_class: container_class)

        initialize_field_data(
          name: :submit,
          label: label || I18n.t("basics.search"),
          form_state: form_state,
          default_classes: [],
          **processed_options
        )
      end

      # Submit buttons only need basic delegations (no help_text, content, etc.)
      delegate :name, :label, :form, :container_class, to: :field_data

      # Form state interface for SearchForm auto-injection
      delegate :form_state, :form_state=, to: :field_data

      def with_form(form)
        field_data.form_state.with_form(form)
        self
      end

      def with_content(&)
        field_data.with_content(&)
        self
      end
    end
  end
end

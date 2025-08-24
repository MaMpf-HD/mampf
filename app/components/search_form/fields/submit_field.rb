# frozen_string_literal: true

module SearchForm
  module Fields
    # Submit field component for form submission button
    #
    # This field type renders a submit button for the search form.
    # Unlike other fields, it doesn't collect user input but triggers
    # form submission. It provides customizable styling and positioning
    # within the form layout.
    #
    # Features:
    # - Customizable button styling with CSS classes
    # - Internationalized default label
    # - Flexible container and inner positioning
    # - Integration with Bootstrap button classes
    #
    # @param button_class [String] CSS classes for the submit button
    # @param inner_class [String] CSS classes for inner container positioning
    #
    # @example Basic submit button
    #   add_submit_field(
    #     label: "Search Now"
    #   )
    #
    # @example Custom styled submit button
    #   add_submit_field(
    #     label: "Find Results",
    #     button_class: "btn btn-success btn-lg",
    #     container_class: "row mt-4",
    #     inner_class: "col-12 d-flex justify-content-end"
    #   )
    class SubmitField < Field
      attr_reader :button_class, :inner_class

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

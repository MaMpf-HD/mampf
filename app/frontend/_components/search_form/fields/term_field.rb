module SearchForm
  module Fields
    # Renders a multi-select field for filtering by terms.
    # This component uses composition to build a multi-select field with an
    # "All" toggle checkbox that controls the selection state of all term options.
    #
    # The field displays terms sourced from the `Term.select_terms` method and
    # provides a convenient checkbox to select or deselect all terms at once.
    # This is particularly useful for quickly switching between viewing content
    # from all terms or from a specific subset of academic terms.
    #
    # @example Basic term field
    #   TermField.new(form_state: form_state)
    #
    # @example Term field with additional options
    #   TermField.new(
    #     form_state: form_state,
    #     disabled: false,
    #     data: { custom_attribute: "value" }
    #   )
    class TermField < ViewComponent::Base
      include Mixins::CompositeFieldMixin

      attr_reader :options

      # Initializes a new TermField component.
      #
      # @param form_state [SearchForm::FormState] The form state object for context
      # @param options [Hash] Additional options passed to the underlying multi-select field
      def initialize(form_state:, **options)
        super()
        @form_state = form_state
        @options = options
      end

      private

        def setup_fields
          @multi_select_field = create_multi_select_field(
            name: :term_ids,
            label: I18n.t("basics.term"),
            help_text: I18n.t("search.fields.helpdesks.term_field"),
            collection: Term.select_terms,
            **options
          )

          @all_checkbox = create_all_checkbox(for_field_name: :term_ids)

          @checkbox_group_wrapper = Fields::Utilities::CheckboxGroupWrapper.new(
            parent_field: @multi_select_field,
            checkboxes: [@all_checkbox]
          )
        end
    end
  end
end

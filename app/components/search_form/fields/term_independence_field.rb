module SearchForm
  module Fields
    # Renders a checkbox for filtering by term independence.
    # This component uses composition to build a checkbox field, pre-configured
    # with a specific name, label, and a default unchecked state.
    class TermIndependenceField < ViewComponent::Base
      attr_accessor :form_state

      # Initializes the TermIndependenceField.
      #
      # This component is specialized and hard-codes its own options for the
      # underlying `CheckboxField`.
      #
      # @param form_state [SearchForm::FormState] The form state object.
      # @param options [Hash] Additional options passed to the checkbox field.
      #   This can be used to pass options like `:container_class`.
      def initialize(form_state:, **options)
        super()
        @form_state = form_state
        @options = options
      end

      delegate :form, to: :form_state

      def with_form(form)
        form_state.with_form(form)
        self
      end

      def before_render
        setup_fields
      end

      private

        def setup_fields
          @checkbox_field = Fields::Primitives::CheckboxField.new(
            name: :term_independent,
            label: I18n.t("admin.course.term_independent"),
            help_text: I18n.t("search.filters.helpdesks.term_independence_filter"),
            checked: false,
            form_state: form_state,
            **@options
          ).with_form(form)
        end
    end
  end
end

module SearchForm
  module Fields
    # Renders a select field for filtering by medium access rights.
    # This component uses composition to build a select field, pre-configured
    # with a specific name, label, and a static collection of access levels
    # (e.g., "All", "Users", "Subscribers").
    class MediumAccessField < ViewComponent::Base
      attr_accessor :form_state

      # Initializes the MediumAccessField.
      #
      # This component is specialized and hard-codes its own options for the
      # underlying `SelectField`.
      #
      # @param form_state [SearchForm::FormState] The form state object.
      # @param options [Hash] Additional options passed to the select field.
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
          @select_field = Fields::SelectField.new(
            name: :access,
            label: I18n.t("basics.access_rights"),
            help_text: I18n.t("search.filters.helpdesks.medium_access_filter"),
            collection: [
              [I18n.t("access.irrelevant"), "irrelevant"],
              [I18n.t("access.all"), "all"],
              [I18n.t("access.users"), "users"],
              [I18n.t("access.subscribers"), "subscribers"],
              [I18n.t("access.locked"), "locked"],
              [I18n.t("access.unpublished"), "unpublished"]
            ],
            selected: "irrelevant",
            form_state: form_state,
            **@options
          ).with_form(form)
        end
    end
  end
end

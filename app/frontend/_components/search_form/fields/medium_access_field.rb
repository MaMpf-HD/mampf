module SearchForm
  module Fields
    # Renders a select field for filtering by medium access rights.
    # This component provides predefined access level options including
    # "irrelevant", "all", "users", "subscribers", "locked", and "unpublished".
    #
    # The field is specialized for content access control and offers a complete
    # range of access levels from public visibility to restricted content. It
    # defaults to "irrelevant" which effectively disables access-based filtering.
    #
    # @example Basic medium access field
    #   MediumAccessField.new(form_state: form_state)
    #
    # @example Medium access field with additional options
    #   MediumAccessField.new(
    #     form_state: form_state,
    #     container_class: "col-md-4"
    #   )
    class MediumAccessField < ViewComponent::Base
      include Mixins::CompositeFieldMixin

      attr_reader :options

      # Initializes a new MediumAccessField component.
      #
      # This component is specialized for access control filtering and provides
      # a predefined collection of access levels without requiring configuration.
      #
      # @param form_state [SearchForm::FormState] The form state object for context
      # @param options [Hash] Additional options passed to the underlying select field,
      #   such as container_class or other styling attributes
      def initialize(form_state:, **options)
        super()
        @form_state = form_state
        @options = options
      end

      private

        def setup_fields
          @select_field = create_select_field(
            name: :access,
            label: I18n.t("basics.access_rights"),
            help_text: I18n.t("search.fields.helpdesks.medium_access_field"),
            collection: access_level_options,
            selected: "irrelevant",
            **options
          )
        end

        def access_level_options
          [
            [I18n.t("access.irrelevant"), "irrelevant"],
            [I18n.t("access.all"), "all"],
            [I18n.t("access.users"), "users"],
            [I18n.t("access.subscribers"), "subscribers"],
            [I18n.t("access.locked"), "locked"],
            [I18n.t("access.unpublished"), "unpublished"]
          ]
        end
    end
  end
end

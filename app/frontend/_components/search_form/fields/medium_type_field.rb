module SearchForm
  module Fields
    # Renders a multi-select field for filtering by medium type (e.g., "WorkedExample",
    # "Quiz"). This component is highly contextual and dynamically alters its
    # behavior, collection, and appearance based on the `purpose` of the search
    # form and the `current_user`'s permissions.
    #
    # The field adapts its configuration based on three main contexts:
    # - "media": Shows all medium types with multi-select and "All" checkbox
    # - "import": Shows importable types only, multi-select enabled, no "All" checkbox
    # - "quiz": Shows quiz types only, single-select, pre-selects "Question", no "All" checkbox
    #
    # User permissions also affect the available medium types, with admin/editor
    # users seeing additional options compared to regular users.
    #
    # @example Basic medium type field for media search
    #   MediumTypeField.new(
    #     form_state: form_state,
    #     current_user: current_user,
    #     purpose: "media"
    #   )
    #
    # @example Quiz-specific medium type field
    #   MediumTypeField.new(
    #     form_state: form_state,
    #     current_user: current_user,
    #     purpose: "quiz"
    #   )
    class MediumTypeField < ViewComponent::Base
      include Mixins::CompositeFieldMixin

      attr_reader :purpose, :current_user, :options

      # Initializes a new MediumTypeField component.
      #
      # The component's behavior is determined by the `purpose` and `current_user`
      # arguments. It dynamically sets its collection, pre-selected values, and
      # HTML attributes (`multiple`, `disabled`) based on these inputs.
      #
      # @param form_state [SearchForm::FormState] The form state object
      # @param current_user [User] The user performing the search. Their role
      #   (e.g., admin, editor) can affect the available medium types
      # @param purpose [String] The context of the search form, which dictates
      #   the component's configuration. Can be "media", "import", or "quiz"
      # @param options [Hash] Additional options passed to the underlying multi-select field
      def initialize(form_state:, current_user:, purpose: "media", **options)
        super()
        @form_state = form_state
        @purpose = purpose
        @current_user = current_user
        @options = options
      end

      private

        def setup_fields
          @multi_select_field = create_multi_select_field(
            name: :types,
            label: I18n.t("basics.types"),
            help_text: I18n.t("search.helpdesks.medium_type_field"),
            collection: media_sorts_select(current_user, purpose),
            selected: sort_preselect(purpose),
            multiple: purpose.in?(["media", "import"]),
            disabled: purpose == "media",
            **options
          )

          setup_checkbox_group unless skip_all_checkbox?
        end

        def setup_checkbox_group
          @all_checkbox = create_all_checkbox(for_field_name: :types)

          @checkbox_group_wrapper = Fields::Utilities::CheckboxGroupWrapper.new(
            parent_field: @multi_select_field,
            checkboxes: [@all_checkbox]
          )
        end

        def skip_all_checkbox?
          purpose.in?(["import", "quiz"])
        end

        def sort_preselect(purpose)
          return "" unless purpose == "quiz"

          "Question"
        end

        def media_sorts_select(current_user, purpose)
          return Medium.select_quizzables if purpose == "quiz"
          return Medium.select_importables if purpose == "import"
          return Medium.select_generic unless current_user.admin_or_editor?

          Medium.select_sorts
        end
    end
  end
end

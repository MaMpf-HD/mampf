module SearchForm
  module Filters
    # Renders a multi-select field for filtering by medium type (e.g., WorkedExample",
    # "Quiz"). This component is highly contextual and dynamically alters its
    # behavior, collection, and appearance based on the `purpose` of the search
    # form and the `current_user`'s permissions.
    class MediumTypeFilter < ViewComponent::Base
      attr_accessor :form_state
      attr_reader :purpose, :current_user

      # Initializes the MediumTypeFilter.
      #
      # The component's behavior is determined by the `purpose` and `current_user`
      # arguments. It dynamically sets its collection, pre-selected values, and
      # HTML attributes (`multiple`, `disabled`) based on these inputs.
      #
      # @param form_state [SearchForm::FormState] The form state object.
      # @param current_user [User] The user performing the search. Their role
      #   (e.g., admin, editor) can affect the available medium types.
      # @param purpose [String] The context of the search form, which dictates
      #   the component's configuration. Can be "media", "import", or "quiz".
      # @param options [Hash] Additional options passed to the components.
      def initialize(form_state:, current_user:, purpose: "media", **options)
        super()
        @form_state = form_state
        @purpose = purpose
        @current_user = current_user
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
          setup_multi_select_field
          setup_checkbox_group unless skip_all_checkbox?
        end

        def setup_multi_select_field
          @multi_select_field = Fields::MultiSelectField.new(
            name: :types,
            label: I18n.t("basics.types"), # Plural for media
            help_text: I18n.t("search.filters.helpdesks.medium_type_filter"),
            collection: media_sorts_select(current_user, purpose),
            selected: sort_preselect(purpose),
            multiple: purpose.in?(["media", "import"]),
            disabled: purpose == "media",
            form_state: form_state,
            **@options
          ).with_form(form)
        end

        def setup_checkbox_group
          setup_checkboxes
          @checkbox_group_wrapper = Utilities::CheckboxGroupWrapper.new(
            parent_field: @multi_select_field,
            checkboxes: [@all_checkbox]
          )
        end

        def setup_checkboxes
          @all_checkbox = Fields::CheckboxField.new(
            name: generate_all_toggle_name(:types),
            label: I18n.t("basics.all"),
            checked: true,
            form_state: form_state,
            container_class: "form-check mb-2",
            stimulus: {
              toggle: true
            }
          ).with_form(form)
        end

        # Conditionally disable the "All" checkbox.
        # The checkbox is skipped for "import" and "quiz" purposes where selecting
        # "All" types is not a valid option.
        #
        # @return [Boolean] `true` if the "All" checkbox should be skipped.
        def skip_all_checkbox?
          purpose.in?(["import", "quiz"])
        end

        def generate_all_toggle_name(name)
          base_name = name.to_s.delete_suffix("_ids").pluralize
          :"all_#{base_name}"
        end

        # Determines the pre-selected value for the select input.
        # For the "quiz" purpose, it defaults to "Question". Otherwise, it is blank.
        #
        # @param purpose [String] The context of the search form.
        # @return [String] The value to be pre-selected, or an empty string.
        def sort_preselect(purpose)
          return "" unless purpose == "quiz"

          "Question"
        end

        # Acts as a factory to generate the appropriate collection of medium types
        # based on the form's purpose and the user's role.
        #
        # @param current_user [User] The user performing the search.
        # @param purpose [String] The context of the search form.
        # @return [Array<Array>] A collection suitable for a select field.
        def media_sorts_select(current_user, purpose)
          return Medium.select_quizzables if purpose == "quiz"
          return Medium.select_importables if purpose == "import"
          return Medium.select_generic unless current_user.admin_or_editor?

          Medium.select_sorts
        end
    end
  end
end

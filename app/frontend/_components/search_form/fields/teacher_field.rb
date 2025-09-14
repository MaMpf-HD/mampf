module SearchForm
  module Fields
    # Renders a multi-select field for filtering by teachers.
    # This component uses composition to build a multi-select field with an
    # "All" toggle checkbox that controls the selection state of all teacher options.
    #
    # The field displays teachers from the `User.select_teachers` collection and
    # provides a convenient checkbox to select or deselect all teachers at once.
    # This is particularly useful for quickly switching between viewing content
    # from all teachers or from a specific subset.
    #
    # @example Basic teacher field
    #   TeacherField.new(form_state: form_state)
    #
    # @example Teacher field with additional options
    #   TeacherField.new(
    #     form_state: form_state,
    #     disabled: false,
    #     data: { custom_attribute: "value" }
    #   )
    class TeacherField < ViewComponent::Base
      include Mixins::CompositeFieldMixin

      attr_reader :options

      # Initializes a new TeacherField component.
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
            name: :teacher_ids,
            label: I18n.t("basics.teachers"),
            help_text: I18n.t("search.fields.helpdesks.teacher_field"),
            collection: User.select_teachers,
            **options
          )

          @all_checkbox = create_all_checkbox(for_field_name: :teacher_ids)

          @checkbox_group_wrapper = Fields::Utilities::CheckboxGroupWrapper.new(
            parent_field: @multi_select_field,
            checkboxes: [@all_checkbox]
          )
        end
    end
  end
end

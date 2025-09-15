module SearchForm
  module Fields
    # Renders a multi-select field for filtering by courses. This component
    # uses composition to build a multi-select field with an "All" toggle checkbox
    # that controls the selection state of all course options.
    #
    # The field displays courses ordered alphabetically by title and provides
    # a convenient checkbox to select or deselect all courses at once. This is
    # particularly useful when users want to quickly toggle between viewing
    # content from all courses or from a specific subset.
    #
    # @example Basic course field
    #   CourseField.new(form_state: form_state)
    #
    # @example Course field with additional options
    #   CourseField.new(
    #     form_state: form_state,
    #     disabled: false,
    #     data: { custom_attribute: "value" }
    #   )
    class CourseField < ViewComponent::Base
      include Mixins::CompositeFieldMixin

      attr_reader :options

      # Initializes a new CourseField component.
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
            name: :course_ids,
            label: I18n.t("basics.courses"),
            help_text: I18n.t("search.helpdesks.course_field"),
            collection: Course.order(:title).pluck(:title, :id),
            **options
          )

          @all_checkbox = create_all_checkbox(for_field_name: :course_ids)

          @checkbox_group_wrapper = Fields::Utilities::CheckboxGroupWrapper.new(
            parent_field: @multi_select_field,
            checkboxes: [@all_checkbox]
          )
        end
    end
  end
end

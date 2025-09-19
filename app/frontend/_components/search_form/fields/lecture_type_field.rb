module SearchForm
  module Fields
    # Multi-select field for filtering by lecture type.
    #
    # Displays lecture types sourced from `Lecture.select_sorts`.
    #
    # @example Basic lecture type field
    #   LectureTypeField.new(form_state: form_state)
    #
    # @example Lecture type field with additional options
    #   LectureTypeField.new(
    #     form_state: form_state,
    #     disabled: false,
    #     data: { custom_attribute: "value" }
    #   )
    class LectureTypeField < ViewComponent::Base
      include Mixins::CompositeFieldMixin

      attr_reader :options

      # Initializes a new LectureTypeField component.
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
            name: :types,
            label: I18n.t("basics.type"),
            help_text: I18n.t("search.helpdesks.lecture_type_field"),
            collection: Lecture.select_sorts,
            **options
          )

          @all_checkbox = create_all_checkbox(for_field_name: :types)

          @checkbox_group_wrapper = Fields::Utilities::CheckboxGroupWrapper.new(
            parent_field: @multi_select_field,
            checkboxes: [@all_checkbox]
          )
        end
    end
  end
end

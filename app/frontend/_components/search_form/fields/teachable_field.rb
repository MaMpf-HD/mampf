module SearchForm
  module Fields
    # Renders a grouped multi-select field for filtering by teachables (Courses
    # and their associated Lectures). This component uses composition to build
    # a multi-select field with checkbox and radio button groups for inheritance options.
    #
    # The field provides sophisticated filtering with three interactive elements:
    # - Grouped multi-select dropdown showing courses and their lectures
    # - "All" checkbox that toggles all selections and controls radio button state
    # - Inheritance radio buttons (with/without) that determine how course selections
    #   are treated (whether to include associated lectures automatically)
    #
    # The component uses advanced Stimulus integration where the "All" checkbox
    # can toggle the radio button group and set inheritance defaults, providing
    # intuitive control over complex hierarchical filtering.
    #
    # @example Basic teachable field
    #   TeachableField.new(form_state: form_state)
    #
    # @example Teachable field with additional options
    #   TeachableField.new(
    #     form_state: form_state,
    #     data: { custom_attribute: "value" }
    #   )
    class TeachableField < ViewComponent::Base
      include Mixins::CompositeFieldMixin

      attr_reader :options

      # Initializes a new TeachableField component.
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
          setup_multi_select_field
          setup_checkbox_group
          setup_radio_group
        end

        def setup_multi_select_field
          @multi_select_field = create_multi_select_field(
            name: :teachable_ids,
            label: I18n.t("basics.associated_to"),
            help_text: I18n.t("search.fields.helpdesks.teachable_field"),
            collection: grouped_teachable_list,
            **options
          )
        end

        def setup_checkbox_group
          @all_checkbox = create_all_checkbox(
            for_field_name: :teachable_ids,
            stimulus: {
              toggle: true,
              toggle_radio_group: "teachable_inheritance",
              default_radio_value: "1"
            }
          )

          @checkbox_group_wrapper = Fields::Utilities::CheckboxGroupWrapper.new(
            parent_field: @multi_select_field,
            checkboxes: [@all_checkbox]
          )
        end

        def setup_radio_group
          @with_inheritance_radio = create_radio_button_field(
            name: :teachable_inheritance,
            value: "1",
            label: I18n.t("basics.with_inheritance"),
            checked: true,
            disabled: true,
            inline: true,
            container_class: "form-check form-check-inline",
            stimulus: { radio_toggle: true, controls_select: false }
          )

          @without_inheritance_radio = create_radio_button_field(
            name: :teachable_inheritance,
            value: "0",
            label: I18n.t("basics.without_inheritance"),
            checked: false,
            disabled: true,
            inline: true,
            container_class: "form-check form-check-inline",
            stimulus: { radio_toggle: true, controls_select: false }
          )

          @radio_group_wrapper = Fields::Utilities::RadioGroupWrapper.new(
            name: :teachable_inheritance,
            parent_field: @multi_select_field,
            radio_buttons: [@with_inheritance_radio, @without_inheritance_radio]
          )
        end

        def grouped_teachable_list
          course_label = I18n.t("basics.course")

          # Single query with proper eager loading
          courses_with_lectures = Course.includes(lectures: :term)
                                        .order(:title)

          courses_with_lectures.map do |course|
            lectures = [["#{course.short_title} #{course_label}", "Course-#{course.id}"]]

            course.lectures.natural_sort_by(&:short_title).each do |lecture|
              lectures << [lecture.short_title, "Lecture-#{lecture.id}"]
            end

            [course.title, lectures]
          end
        end
    end
  end
end

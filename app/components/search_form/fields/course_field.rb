module SearchForm
  module Fields
    # Renders a multi-select field for filtering by courses. This component
    # uses composition to build a multi-select field with an all toggle checkbox
    # and an optional "Edited Courses" button.
    class CourseField < ViewComponent::Base
      attr_accessor :form_state

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
          setup_multi_select_field
          setup_checkbox_group
        end

        def setup_multi_select_field
          @multi_select_field = Fields::Primitives::MultiSelectField.new(
            name: :course_ids,
            label: I18n.t("basics.courses"),
            help_text: I18n.t("search.filters.helpdesks.course_filter"),
            collection: Course.order(:title).pluck(:title, :id),
            form_state: form_state,
            **@options
          ).with_form(form)
        end

        def setup_checkbox_group
          setup_checkboxes
          @checkbox_group_wrapper = Fields::Utilities::CheckboxGroupWrapper.new(
            parent_field: @multi_select_field,
            checkboxes: [@all_checkbox]
          )
        end

        def setup_checkboxes
          @all_checkbox = Fields::Primitives::CheckboxField.new(
            name: generate_all_toggle_name(:course_ids),
            label: I18n.t("basics.all"),
            checked: true,
            form_state: form_state,
            container_class: "form-check mb-2",
            stimulus: {
              toggle: true
            }
          ).with_form(form)
        end

        def generate_all_toggle_name(name)
          base_name = name.to_s.delete_suffix("_ids").pluralize
          :"all_#{base_name}"
        end
    end
  end
end

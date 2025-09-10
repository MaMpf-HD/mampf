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
        @show_edited_courses_button = false
        @current_user = nil
      end

      delegate :form, to: :form_state

      def with_form(form)
        form_state.with_form(form)
        self
      end

      # A configuration method to enable and render the "Edited Courses" button.
      # It stores the user and sets a flag to show the button in the content area.
      #
      # @param current_user [User] The user whose edited courses should be pre-selected.
      # @return [self] Returns the component instance to allow for method chaining.
      def with_edited_courses_button(current_user)
        @show_edited_courses_button = true
        @current_user = current_user
        self
      end

      # A helper method for the template to determine if the content area
      # (containing the "Edited Courses" button) should be rendered.
      #
      # @return [Boolean] `true` if the button has been enabled.
      def show_edited_courses_button?
        @show_edited_courses_button
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
          @multi_select_field = Fields::MultiSelectField.new(
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
          @all_checkbox = Fields::CheckboxField.new(
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

        def render_edited_courses_button
          return unless @current_user

          tag.button(
            I18n.t("buttons.edited_courses"),
            id: "tags-edited-courses",
            type: "button",
            class: "btn btn-sm btn-outline-info",
            data: {
              courses: @current_user.edited_courses.map(&:id).to_json,
              action: "click->search-form#fillCourses"
            }
          )
        end
    end
  end
end

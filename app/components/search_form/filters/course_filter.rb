module SearchForm
  module Filters
    # Renders a multi-select field for filtering by courses. This component
    # extends `MultiSelectField` and adds an optional "Edited Courses" button.
    # This button, when clicked, uses JavaScript to pre-select the courses that
    # a given user has edited.
    class CourseFilter < Fields::MultiSelectField
      # Initializes the CourseFilter.
      #
      # This component is specialized and hard-codes its own options for the
      # underlying `MultiSelectField`, such as `:name`, `:label`, and `:collection`.
      # It also initializes the state for the optional "Edited Courses" button.
      #
      # @param ** [Hash] Catches any other keyword arguments, which are passed
      #   to the superclass.
      def initialize(**)
        super(
          name: :course_ids,
          label: I18n.t("basics.courses"),
          help_text: I18n.t("admin.tag.info.search_course"),
          collection: Course.order(:title).pluck(:title, :id),
          **
        )

        @show_edited_courses_button = false
        @current_user = nil
      end

      # A configuration method to enable and render the "Edited Courses" button.
      # It stores the user, sets a flag, and populates the field's `content`
      # slot with the button's HTML.
      #
      # @param current_user [User] The user whose edited courses should be pre-selected.
      # @return [self] Returns the component instance to allow for method chaining.
      def with_edited_courses_button(current_user)
        @show_edited_courses_button = true
        @current_user = current_user

        # Set the content for the field
        with_content do
          render_edited_courses_button
        end

        self
      end

      # A helper method for the template to determine if the content area
      # (containing the "Edited Courses" button) should be rendered.
      #
      # @return [Boolean] `true` if the button has been enabled.
      def show_edited_courses_button?
        @show_edited_courses_button
      end

      private

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

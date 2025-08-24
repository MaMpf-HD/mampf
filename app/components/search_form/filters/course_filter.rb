module SearchForm
  module Filters
    class CourseFilter < Fields::MultiSelectField
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

      def with_edited_courses_button(current_user)
        @show_edited_courses_button = true
        @current_user = current_user

        # Set the content for the field
        with_content do
          render_edited_courses_button
        end

        self
      end

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

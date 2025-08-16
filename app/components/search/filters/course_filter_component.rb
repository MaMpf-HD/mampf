# app/components/search/filters/course_filter_component.rb
module Search
  module Filters
    class CourseFilterComponent < Search::MultiSelectComponent
      def initialize
        super(
          name: :course_ids,
          label: I18n.t("basics.courses"),
          help_text: I18n.t("admin.tag.info.search_course"),
          collection: options_for_select(
            Course.all.pluck(:title, :id).natural_sort_by(&:first), nil
          )
        )
      end

      def render_edited_courses_button(current_user)
        tag.button(
          I18n.t("buttons.edited_courses"),
          id: "tags-edited-courses",
          type: "button",
          class: "btn btn-sm btn-outline-info",
          data: { courses: current_user.edited_courses.map(&:id).to_json }
        )
      end
    end
  end
end

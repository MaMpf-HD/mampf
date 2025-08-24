# frozen_string_literal: true

# Search Form Filters Module
#
# This module contains specialized filter components that extend the base field
# types with domain-specific functionality for different search contexts.
# Each filter knows how to generate its collection data efficiently and
# provides the appropriate form field type for its use case.
#
# Filter categories:
# - Course/Lecture filters: CourseFilter, LectureFilter, LectureTypeFilter
# - Content filters: TagFilter, TagTitleFilter, MediumTypeFilter
# - User filters: EditorFilter, TeacherFilter, TeachableFilter
# - Academic filters: TermFilter, ProgramFilter, TermIndependenceFilter
# - Search filters: FulltextFilter, AnswerCountFilter, PerPageFilter
# - Access filters: MediumAccessFilter, LectureScopeFilter
#
# All filters use optimized database queries to avoid N+1 problems and
# integrate with the Rails internationalization system for labels.

module SearchForm
  module Filters
    # Course filter for selecting specific courses
    #
    # This filter provides a multi-select dropdown for choosing courses.
    # It includes an optional "Fill with edited courses" button that allows
    # users to quickly select all courses they have editing permissions for.
    #
    # Features:
    # - Multi-select course dropdown ordered alphabetically
    # - Optional "edited courses" quick-fill button
    # - Optimized database query using pluck for performance
    # - Integration with user permissions for editor functionality
    #
    # @example Basic course filter
    #   add_course_filter
    #
    # @example Course filter with edited courses button
    #   add_course_filter.with_edited_courses_button(current_user)
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

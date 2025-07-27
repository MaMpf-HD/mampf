module Filters
  class CourseFilter < BaseFilter
    def call
      # This single check handles nil, [], [""], [nil], etc.
      no_specific_courses = params[:course_ids].to_a.compact_blank.empty?

      return scope if params[:all_courses] == "1" || no_specific_courses

      scope.joins(:courses)
           .where(courses: { id: params[:course_ids] })
    end
  end
end

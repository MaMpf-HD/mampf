# Filters a scope to include only records associated with specific courses.
#
# This filter is skipped if the 'all_courses' parameter is set to '1' or if
# no specific course IDs are provided in the `course_ids` parameter.
#
# When active, it joins the `courses` table and filters the scope to include
# only records associated with the given course IDs.
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

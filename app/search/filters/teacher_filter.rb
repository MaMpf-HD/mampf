# Filters a scope to include only records associated with specific teachers.
#
# This filter is skipped if the 'all_teachers' parameter is set to '1' or if
# no teacher IDs are provided in the `teacher_ids` parameter.
#
# When active, it filters the scope by the given teacher IDs.
module Search
  module Filters
    class TeacherFilter < BaseFilter
      def call
        return scope if skip_filter?(all_param: :all_teachers, ids_param: :teacher_ids)

        scope.where(teacher_id: params[:teacher_ids])
      end
    end
  end
end

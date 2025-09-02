# Filters a scope to include only records associated with specific programs.
#
# This filter is skipped if the 'all_programs' parameter is set to '1' or if
# no program IDs are provided.
#
# When active, it dynamically determines the correct join path based on the
# model being filtered (e.g., `Course` or `Lecture`) to filter by the given
# program IDs. It does not modify the scope for unsupported models.
module Search
  module Filters
    class ProgramFilter < BaseFilter
      def filter
        return scope if skip_filter?(all_param: :all_programs, ids_param: :program_ids)

        join_path = case scope.klass.name
                    when "Course"
                      :divisions
                    when "Lecture"
                      { course: :divisions }
                    else
                      return scope
        end

        scope.joins(join_path)
             .where(divisions: { program_id: params[:program_ids] })
      end
    end
  end
end

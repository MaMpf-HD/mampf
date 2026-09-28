# Filters a scope to include only records associated with specific programs.
#
# This filter is skipped if the 'all_programs' parameter is set to '1' or if
# no program IDs are provided.
#
# When active, filters users by their own `program_id` and joins courses
# and lectures through their divisions. It does not modify the scope for
# unsupported models.
module Search
  module Filters
    class ProgramFilter < BaseFilter
      def filter
        return scope if skip_filter?(all_param: :all_programs, ids_param: :program_ids)

        join_path = case scope.klass.name
                    when "User"
                      return scope.where(program_id: params[:program_ids])
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

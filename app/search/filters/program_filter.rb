module Filters
  class ProgramFilter < BaseFilter
    def call
      return scope if params[:all_programs] == "1" || params[:program_ids].blank?

      join_path = case scope.klass.name
                  when "Course"
                    :divisions
                  when "Lecture"
                    { course: :divisions }
                  else
                    # If the filter is used on an unsupported model, do nothing.
                    return scope
      end

      scope.joins(join_path)
           .where(divisions: { program_id: params[:program_ids] })
    end
  end
end

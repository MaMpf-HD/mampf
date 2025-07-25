module Filters
  class ProgramFilter < BaseFilter
    def call
      return scope if params[:all_programs] == "1" || params[:program_ids].blank?

      scope.joins(:divisions)
           .where(divisions: { program_id: params[:program_ids] })
           .distinct
    end
  end
end

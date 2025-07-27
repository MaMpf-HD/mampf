module Filters
  class TeacherFilter < BaseFilter
    def call
      return scope if params[:all_teachers] == "1" || params[:teacher_ids].blank?

      scope.where(teacher_id: params[:teacher_ids])
    end
  end
end

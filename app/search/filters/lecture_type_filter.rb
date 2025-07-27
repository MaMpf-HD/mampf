module Filters
  class LectureTypeFilter < BaseFilter
    def call
      return scope if params[:all_types] == "1" || params[:types].blank?

      scope.where(sort: params[:types])
    end
  end
end

module Filters
  class MediumAccessFilter < BaseFilter
    def call
      return scope if params[:access].blank? || params[:access] == "irrelevant"

      if params[:access] == "unpublished"
        scope.where(released: nil)
      else
        scope.where(released: params[:access])
      end
    end
  end
end

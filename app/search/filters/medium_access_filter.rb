# Filters media by their `released` status (e.g., 'all', 'subscribers', 'unpublished').
#
# This filter is skipped if the `access` parameter is blank or set to 'irrelevant'.
#
# It handles a special case for 'unpublished', which corresponds to a `nil`
# value in the `released` column. For all other values, it filters for records
# where the `released` column matches the provided `access` parameter.
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

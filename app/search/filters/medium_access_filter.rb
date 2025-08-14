# Filters media by their `released` status (e.g., 'all', 'subscribers', 'unpublished').
#
# This filter is skipped if the `access` parameter is blank or set to 'irrelevant'.
#
# It handles a special case for 'unpublished', which corresponds to a `nil`
# value in the `released` column. For all other values, it filters for records
# where the `released` column matches the provided `access` parameter.
module Search
  module Filters
    class MediumAccessFilter < BaseFilter
      def call
        access_param = params[:access]
        return scope if access_param.blank? || access_param == "irrelevant"

        released_value = access_param == "unpublished" ? nil : access_param

        scope.where(released: released_value)
      end
    end
  end
end

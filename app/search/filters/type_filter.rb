# Filters a scope by its `sort` attribute (e.g., 'Question', 'Remark', etc.).
#
# This filter is skipped if the 'all_types' parameter is set to '1' or if
# no specific types are provided in the `types` parameter.
#
# When active, it filters the scope to include only records whose `sort`
# attribute matches one of the values provided in the `types` parameter.
module Search
  module Filters
    class TypeFilter < BaseFilter
      def call
        return scope if skip_filter?(all_param: :all_types, ids_param: :types)

        scope.where(sort: params[:types])
      end
    end
  end
end

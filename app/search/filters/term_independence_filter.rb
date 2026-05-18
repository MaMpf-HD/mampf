# Filters a scope to include only records that are marked as term-independent.
#
# This filter is only active when the `term_independent` parameter is set
# to '1'. When active, it filters for records where the `term_independent`
# attribute is `true`.
module Search
  module Filters
    class TermIndependenceFilter < BaseFilter
      def filter
        return scope unless params[:term_independent] == "1"

        scope.where(term_independent: true)
      end
    end
  end
end

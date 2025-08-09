# Filters media based on a list of "teachable" entities (Courses, Lectures,
# Lessons). It uses the TeachableParser to resolve the full list of relevant
# teachable IDs, including handling inheritance logic.
#
# For each valid identifier, it constructs a query to match the
# `teachable_type` and `teachable_id`. These conditions are then combined
# with OR to find all media that belong to any of the specified teachables.
module Search
  module Filters
    class TeachableFilter < BaseFilter
      def call
        # First, check if the user actually provided any teachable IDs to filter by.
        # If not, the filter is inactive and should return the original scope.
        return scope if params[:teachable_ids].to_a.compact_blank.empty?

        grouped_teachables = Search::Parsers::TeachableParser.call(params)

        # If the parser returns an empty hash, it means the user provided IDs,
        # but none were valid. In this case, the result should be an empty set.
        return scope.none if grouped_teachables.empty?

        # Build a query for each teachable type and chain them with .or()
        queries = grouped_teachables.map do |type, ids|
          scope.where(teachable_type: type, teachable_id: ids)
        end

        # Chain all individual conditions together with OR.
        queries.reduce(:or)
      end
    end
  end
end

# Filters a scope of records by associated tags, supporting both "AND" and "OR" logic.
#
## This filter is model-agnostic and works for any model that has a `tags`
# association (e.g., Course, Medium).
#
# This filter is skipped if the 'all_tags' parameter is set to '1' or if
# no specific tag IDs are provided.
#
# It supports two modes based on the `tag_operator` parameter:
# - 'and': Filters for records that are associated with *all* of the
#   specified tags.
# - 'or' (default): Filters for records that are associated with *any* of the
#   specified tags.
module Search
  module Filters
    class TagFilter < BaseFilter
      def call
        return scope unless scope.klass.reflect_on_association(:tags)
        return scope if skip_filter?(all_param: :all_tags, ids_param: :tag_ids)

        tag_ids = params[:tag_ids].map(&:to_i)
        table_name = scope.klass.table_name
        primary_key = scope.klass.primary_key

        if params[:tag_operator] == "and"
          # Find the IDs of records within the current scope that have
          # all the specified tags.
          matching_ids_subquery = scope.joins(:tags)
                                       .where(tags: { id: tag_ids })
                                       .group("#{table_name}.#{primary_key}")
                                       .having("COUNT(DISTINCT tags.id) = ?", tag_ids.count)
                                       .select("#{table_name}.#{primary_key}")

          # Use the subquery to filter the scope. This results in a single
          # SQL query and keeps the final scope clean for further chaining.
          scope.where(primary_key => matching_ids_subquery)
        else
          scope.joins(:tags).where(tags: { id: tag_ids }).distinct
        end
      end
    end
  end
end

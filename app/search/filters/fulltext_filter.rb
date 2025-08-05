# Applies a full-text search to the scope if a search term is provided.
#
# This filter uses the `search_by_title` scope (defined by `pg_search`)
# to perform the search and adds the `with_pg_search_rank` scope to make
# the search rank available for ordering.
#
# If the `fulltext` parameter is blank, it returns the scope unmodified.
module Search
  module Filters
    class FulltextFilter < BaseFilter
      def call
        search_term = params[:fulltext]
        return scope if search_term.blank?

        scope.search_by_title(search_term).with_pg_search_rank
      end
    end
  end
end

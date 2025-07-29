module Filters
  class FulltextFilter < BaseFilter
    def call
      search_term = params[:fulltext]
      return scope if search_term.blank?

      scope.search_by_title(search_term).with_pg_search_rank
    end
  end
end

module Filters
  class FulltextFilter < BaseFilter
    def call
      return scope unless fulltext_param

      search_term = params[fulltext_param]
      return scope if search_term.blank?

      scope.search_by_title(search_term).with_pg_search_rank
    end
  end
end

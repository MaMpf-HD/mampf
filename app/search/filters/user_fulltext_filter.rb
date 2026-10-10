# Finds people by the fulltext of the support search. A fulltext with an "@"
# is taken as an address, anything else as the beginnings of words in names,
# addresses and numbers. With similar set, both look for near misses instead,
# so that a typo still leads to the person.
#
# Every branch selects pg_search_rank, which Sorters::UserSearchSorter
# puts first.
module Search
  module Filters
    class UserFulltextFilter < BaseFilter
      def filter
        fulltext = params[:fulltext]
        return scope if fulltext.blank?
        return address_scope(fulltext) if fulltext.include?("@")

        name_scope(fulltext).with_pg_search_rank
      end

      private

        def address_scope(address)
          return scope.search_by_similar_address(address) if params[:similar]

          scope.search_by_address(address)
        end

        def name_scope(fulltext)
          return scope.search_by_similar_name(fulltext) if params[:similar]

          scope.search_by_word_start(fulltext)
        end
    end
  end
end

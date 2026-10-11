# Finds people by the fulltext of the support search. A fulltext with an "@"
# is taken as an address, anything else as the beginnings of words in names,
# addresses and numbers. With similar set, both look for near misses instead,
# so that a typo still leads to the person.
#
# The name searches are pg_search scopes and therefore live in User; the
# address searches have no other caller and stay here.
#
# Every branch selects pg_search_rank, which Sorters::UserSearchSorter
# puts first.
module Search
  module Filters
    class UserFulltextFilter < BaseFilter
      ADDRESS_SIMILARITY = 0.5

      def filter
        fulltext = params[:fulltext]
        return scope if fulltext.blank?
        return address_scope(fulltext.strip) if fulltext.include?("@")

        name_scope(fulltext).with_pg_search_rank
      end

      private

        def address_scope(address)
          return similar_address_scope(address) if params[:similar]

          address_start_scope(address)
        end

        def name_scope(fulltext)
          return scope.search_by_similar_name(fulltext) if params[:similar]

          scope.search_by_word_start(fulltext)
        end

        # Matches addresses from their beginning: the full-text search keeps an
        # address as one word, so "emmy@example" would match nothing.
        def address_start_scope(address)
          scope.where(users[:email].matches("#{User.sanitize_sql_like(address)}%"))
               .select(users[Arel.star],
                       similarity(Arel::Nodes.build_quoted(address), users[:email])
                         .as("pg_search_rank"))
        end

        # Compares only what comes before the "@": the addresses of one
        # university share what comes after it. Finds the owner of an address
        # registered with a typo.
        def similar_address_scope(address)
          searched = address.split("@").first.to_s
          scope.where(local_part_similarity(searched).gteq(ADDRESS_SIMILARITY))
               .select(users[Arel.star], local_part_similarity(searched).as("pg_search_rank"))
        end

        def local_part_similarity(searched)
          local_part = Arel::Nodes::NamedFunction.new(
            "split_part", [users[:email], Arel::Nodes.build_quoted("@"),
                           Arel::Nodes.build_quoted(1)]
          )
          similarity(Arel::Nodes.build_quoted(searched), local_part)
        end

        def similarity(left, right)
          Arel::Nodes::NamedFunction.new("similarity", [left, right])
        end

        def users
          User.arel_table
        end
    end
  end
end

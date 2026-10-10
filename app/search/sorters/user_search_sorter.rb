# Lists people by last name, first name and address. When a fulltext was
# given, the closest matches come first and only ties go by name. The name
# columns join the SELECT list because the search runs with DISTINCT.
module Search
  module Sorters
    class UserSearchSorter < BaseSorter
      def sort
        names = model_class.default_search_order
        order = search_params[:fulltext].present? ? "pg_search_rank DESC, #{names}" : names

        with_all_columns.select(names).reorder(Arel.sql(order))
      end

      private

        def with_all_columns
          return scope if scope.select_values.any?

          scope.select(model_class.arel_table[Arel.star])
        end
    end
  end
end

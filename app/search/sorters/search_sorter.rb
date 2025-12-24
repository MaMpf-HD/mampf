# Applies the correct sorting to a search result scope.
# It prioritizes sorting by full-text search rank if a search
# term is present. Otherwise, it falls back to the model's defined default
# search order. It also ensures that any columns required for sorting are
# included in the SELECT statement to prevent database errors when using DISTINCT.
module Search
  module Sorters
    class SearchSorter < BaseSorter
      # Applies the sorting logic.
      def sort
        return scope if fulltext_search? || !orderable?
        return apply_keyset_order if keyset_mode?

        apply_default_order
      end

      private

        # Checks if a full-text search is being performed.
        def fulltext_search?
          search_params[:fulltext].present?
        end

        # Checks if the model has a valid default search order defined.
        def orderable?
          model_class.respond_to?(:default_search_order) &&
            model_class.default_search_order.present?
        end

        # Memoizes the default order expression from the model.
        def order_expression
          @order_expression ||= model_class.default_search_order
        end

        # Adds any necessary `left_outer_joins` that are required for the default
        # ordering of the model.
        def add_required_joins(current_scope)
          return current_scope unless model_class.respond_to?(:default_search_order_joins)

          current_scope.left_outer_joins(model_class.default_search_order_joins)
        end

        # Applies the default order and modifies the SELECT list to include
        # the ordering columns.
        def apply_default_order
          # The order expression string might contain ASC/DESC, which is invalid
          # in a SELECT list. We need to extract just the column names for the SELECT.
          select_columns_sql = order_expression.to_s.gsub(/\s+(ASC|DESC)\b/i, "")
          select_expression = Arel.sql(select_columns_sql)

          scope_with_joins = add_required_joins(scope)

          # Always include the order expression in the SELECT list to prevent errors
          # when .distinct is used.
          scope_with_joins.select(model_class.arel_table[Arel.star], select_expression)
                          .order(order_expression)
        end

        # Applies keyset-compatible ordering and ensures ORDER BY expressions
        # are present in the SELECT list to satisfy DISTINCT.
        def apply_keyset_order
          scope_with_joins = add_required_joins(scope)
          parts = Search::Pagination::OrderParser.parse(order_expression)

          select_parts = [model_class.arel_table[Arel.star]]
          order_parts = []
          parts.each do |alias_name, expr, dir|
            select_parts << Arel.sql("#{expr} AS #{alias_name}")
            order_parts << Arel.sql("#{alias_name} #{dir}")
          end

          subquery = scope_with_joins.select(*select_parts)

          model_class.from(subquery, :keyset_subquery)
                     .select(Arel.sql("keyset_subquery.*"))
                     .order(*order_parts)
        end

      # No longer needed
    end
  end
end

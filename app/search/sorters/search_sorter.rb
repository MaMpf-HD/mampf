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

        # Applies keyset-compatible ordering with aliased columns for Pagy.
        # Extracts column mappings from the model's pagy_keyset_config and
        # default_search_order, then adds them to SELECT with proper aliases.
        #
        # TODO:
        # The sorter (when in keyset_mode) will add the ordering columns from
        # the model's default_search_order as SELECT aliases that match the keys
        # in pagy_keyset_config. This allows Pagy to extract and use the keyset
        # values for pagination.
        def apply_keyset_order
          scope_with_joins = add_required_joins(scope)
          return scope_with_joins unless model_class.respond_to?(:pagy_keyset_config)

          keyset_config = model_class.pagy_keyset_config[:keyset]
          return scope_with_joins unless keyset_config

          # Parse the order expression to extract table.column mappings
          order_mappings = parse_order_expression_for_keyset(keyset_config)

          # Build SELECT with aliased columns
          select_parts = [model_class.arel_table[Arel.star]]
          order_parts = []

          order_mappings.each do |alias_name, (column_expr, direction)|
            select_parts << Arel.sql("#{column_expr} AS #{alias_name}")
            order_parts << Arel.sql("#{alias_name} #{direction}")
          end

          scope_with_joins.select(*select_parts).order(*order_parts)
        end

        # Parses the default_search_order SQL string to extract column expressions
        # and map them to the keyset config keys.
        def parse_order_expression_for_keyset(keyset_config)
          order_sql = order_expression.to_s
          mappings = {}

          # Split by comma to get individual order clauses
          order_clauses = order_sql.split(",").map(&:strip)

          keyset_config.each_with_index do |(key, direction), index|
            next if index >= order_clauses.size

            clause = order_clauses[index]
            # Extract column expression and direction
            # e.g., "terms.year DESC" -> ["terms.year", "DESC"]
            match = clause.match(/^(.+?)\s+(ASC|DESC)$/i)
            if match
              column_expr = match[1].strip
              mappings[key] = [column_expr, direction.to_s.upcase]
            end
          end

          mappings
        end
    end
  end
end

module Search
  module Pagination
    module OrderParser
      module_function

      # Builds the necessary components for keyset pagination from an order expression.
      #
      # @param order_expression [Arel::Nodes::Ordering, String] The ORDER BY expression.
      # @return [Hash] A hash containing:
      #   - :select_parts [Array<Arel::Nodes::SqlLiteral>] The SELECT parts for ordering columns.
      #   - :order_parts [Array<Arel::Nodes::SqlLiteral>] The ORDER BY parts.
      #   - :keyset [Hash{Symbol => Symbol}] The keyset mapping alias names to directions.
      def build(order_expression)
        parts = parse(order_expression)
        select_parts = parts.map { |alias_name, expr, _dir| Arel.sql("#{expr} AS #{alias_name}") }
        order_parts = parts.map { |alias_name, _expr, dir| Arel.sql("#{alias_name} #{dir}") }
        keyset = parts.to_h { |alias_name, _expr, dir| [alias_name, dir] }
        { select_parts: select_parts, order_parts: order_parts, keyset: keyset }
      end

      # Extracts the keyset hash from the order expression.
      def keyset_from(order_expression)
        build(order_expression)[:keyset]
      end

      private

        # Parses an order expression string into component parts.
        #
        # @param order_expression [Arel::Nodes::Ordering, String] The ORDER BY expression to parse.
        # @return [Array<Array<Symbol, String, Symbol>>] An array of tuples containing:
        #   - alias_name: A symbol like :keyset_1, :keyset_2, etc.
        #   - expr: The SQL expression string (e.g. column name)
        #   - dir: The direction as a symbol (:asc or :desc)
        def parse(order_expression)
          sql = order_expression.to_s
          clauses = sql.split(",").map(&:strip)
          clauses.map.with_index(1) do |clause, idx|
            m = clause.match(/^(.+?)\s+(ASC|DESC)$/i)
            next unless m

            expr = m[1].strip
            dir  = m[2].downcase.to_sym
            alias_name = :"keyset_#{idx}"
            [alias_name, expr, dir]
          end.compact
        end
    end
  end
end

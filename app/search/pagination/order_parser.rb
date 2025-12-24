module Search
  module Pagination
    module OrderParser
      module_function

      # Parses the order expression into an array of [alias_name, expression, direction].
      # For example, "title DESC, created_at ASC" becomes:
      # [[:keyset_1, "title", :desc], [:keyset_2, "created_at", :asc]]
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

      # Builds the SELECT parts and ORDER BY parts from the order expression.
      # Returns a hash with :select_parts, :order_parts, and :keyset.
      def build(order_expression)
        parts = parse(order_expression)
        select_parts = parts.map { |alias_name, expr, _dir| Arel.sql("#{expr} AS #{alias_name}") }
        order_parts = parts.map { |alias_name, _expr, dir| Arel.sql("#{alias_name} #{dir}") }
        keyset = parts.to_h { |alias_name, _expr, dir| [alias_name, dir] }
        { select_parts: select_parts, order_parts: order_parts, keyset: keyset }
      end

      def keyset_from(order_expression)
        build(order_expression)[:keyset]
      end
    end
  end
end

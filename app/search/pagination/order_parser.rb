module Search
  module Pagination
    module OrderParser
      module_function

      # Parses a comma-separated ORDER BY SQL expression string and returns
      # an array of [alias, expression, direction] with stable alias names.
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

      # Builds a hash suitable for the KeysetPager: { alias => direction }
      def keyset_from(order_expression)
        parse(order_expression).to_h { |alias_name, _expr, dir| [alias_name, dir] }
      end
    end
  end
end

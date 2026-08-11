module RuboCop
  module Cop
    module Mampf
      # Forbids raw `CSV.generate` / `CSV.open` in application code. Use
      # `SafeCsv.generate`, which sanitizes every written row against CSV /
      # spreadsheet formula injection (CWE-1236) so callers cannot forget to.
      #
      # @example
      #   # bad
      #   CSV.generate { |csv| csv << user_supplied_row }
      #
      #   # good
      #   SafeCsv.generate { |csv| csv << user_supplied_row }
      class NoRawCsv < Base
        MSG = "Use `SafeCsv.generate` instead of `CSV.%<method>s` so cells are " \
              "sanitized against CSV injection (CWE-1236).".freeze

        # @!method raw_csv(node)
        def_node_matcher :raw_csv, <<~PATTERN
          (send (const {nil? cbase} :CSV) ${:generate :open} ...)
        PATTERN

        def on_send(node)
          raw_csv(node) do |method|
            add_offense(node, message: format(MSG, method: method))
          end
        end
      end
    end
  end
end

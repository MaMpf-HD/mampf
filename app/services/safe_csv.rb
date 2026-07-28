require "csv"

# Drop-in wrapper around Ruby's CSV that sanitizes every written row against CSV /
# spreadsheet formula injection (CWE-1236) automatically, so callers cannot forget
# to run values through CsvSafe. Use this instead of CSV.generate / CSV.open --
# raw CSV in app/lib is forbidden by the Mampf/NoRawCsv RuboCop cop.
module SafeCsv
  # Mirrors CSV.generate, but yields a writer whose `<<` sanitizes each row.
  def self.generate(**)
    CSV.generate(**) do |csv|
      yield(Writer.new(csv))
    end
  end

  # Minimal sanitizing wrapper around a CSV object. Only exposes row appending, so
  # sanitization cannot be bypassed -- that is the whole point of the wrapper.
  class Writer
    def initialize(csv)
      @csv = csv
    end

    def <<(row)
      @csv << CsvSafe.row(Array(row))
      self
    end
    alias add_row <<
  end
end

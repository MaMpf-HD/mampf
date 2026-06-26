# Neutralizes CSV / spreadsheet formula injection (CWE-1236) in exported cells.
#
# Spreadsheet applications (Excel, LibreOffice, Google Sheets) evaluate a cell
# as a formula when its content starts with one of the trigger characters below.
# A user-controlled value such as "=cmd|'/c calc'!A1" would then execute when a
# recipient opens the exported file. We neutralize such values by prefixing them
# with a single quote, which forces the spreadsheet to treat the cell as text.
#
# Sanitization happens at the CSV-writing boundary on purpose: the threat is
# specific to the spreadsheet context, so the stored data (e.g. user names) stays
# untouched everywhere else in the application.
class CsvSafe
  FORMULA_TRIGGERS = ["=", "+", "-", "@", "\t", "\r"].freeze

  class << self
    # Sanitizes a single cell value. Non-string values (numbers, dates, nil)
    # cannot carry a formula payload and are returned unchanged.
    def cell(value)
      return value unless value.is_a?(String)
      return value unless value.start_with?(*FORMULA_TRIGGERS)

      "'#{value}"
    end

    # Sanitizes every cell of a row.
    def row(values)
      values.map { |value| cell(value) }
    end
  end
end

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
  # Spreadsheet formula leaders. A cell is dangerous if its first *non-whitespace*
  # character is one of these: leading whitespace does not reliably neutralize the
  # payload (some apps trim the cell before evaluating), so we look past it.
  FORMULA_TRIGGERS = ["=", "+", "-", "@"].freeze
  # Control characters that are dangerous as the literal first character of a cell.
  CONTROL_TRIGGERS = ["\t", "\r", "\n"].freeze

  class << self
    # Sanitizes a single cell value. Non-string values (numbers, dates, nil)
    # cannot carry a formula payload and are returned unchanged.
    def cell(value)
      return value unless value.is_a?(String)
      return value unless dangerous?(value)

      "'#{value}"
    end

    # A cell is dangerous if it begins with a control-char trigger, or if its
    # first non-whitespace character is a formula trigger (whitespace-prefix bypass).
    def dangerous?(value)
      value.start_with?(*CONTROL_TRIGGERS) ||
        value.lstrip.start_with?(*FORMULA_TRIGGERS)
    end

    # Sanitizes every cell of a row.
    def row(values)
      values.map { |value| cell(value) }
    end
  end
end

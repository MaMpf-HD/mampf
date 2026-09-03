module Assessment
  class StickyColumnLayout
    WIDTHS = {
      team: 200,
      tutorial: 100,
      status: 100,
      total: 100,
      grade: 110,
      note: 180,
      graded_by: 120,
      graded_at: 120,
      action: 200,
      correction: 200
    }.freeze

    def initialize(left_columns:, right_columns:)
      @left_columns = left_columns
      @right_columns = right_columns
    end

    # left-anchored columns accumulate left-to-right
    def left_offsets
      offset = 0
      @left_columns.each_with_object({}) do |key, acc|
        acc[key] = offset
        offset += WIDTHS.fetch(key)
      end
    end

    # right-anchored columns accumulate right-to-left
    # array order = visual order from the right edge inward
    def right_offsets
      offset = 0
      @right_columns.reverse.each_with_object({}) do |key, acc|
        acc[key] = offset
        offset += WIDTHS.fetch(key)
      end
    end
  end
end

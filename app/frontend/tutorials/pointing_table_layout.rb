# Which columns of the pointing table are pinned to an edge, and how wide
# every column is. The CSS reads both as variables, so a column set for a
# different kind of assessment - a talk's grade, an exam's - is one entry
# here and no new stylesheet.
class PointingTableLayout
  class UnsupportedAssessableError < StandardError; end

  WIDTHS = {
    team: 200,
    tutorial: 120,
    status: 170,
    task: 90,
    total: 100,
    save: 90,
    hand_in: 140,
    correction: 140
  }.freeze

  # A sheet pins the team on the left and saving on the right; everything
  # else scrolls, so the tasks get the width between them.
  def self.for(assessable:)
    case assessable
    when Assignment
      new(left: [:team], right: [:save])
    else
      raise(UnsupportedAssessableError, "No pointing table layout for #{assessable.class}")
    end
  end

  attr_reader :left, :right

  def initialize(left:, right:)
    @left = left
    @right = right
  end

  def pinned?(column)
    left.include?(column) || right.include?(column)
  end

  def column_class(column)
    css = "#{column.to_s.dasherize}-col"
    pinned?(column) ? "sticky-col #{css}" : css
  end

  # Left pins accumulate from the left edge, right pins from the right edge.
  def offsets
    left_offsets = left.each_with_index.to_h { |column, i| [column, width_of(left[0, i])] }
    right_offsets = right.reverse.each_with_index.to_h do |column, i|
      [column, width_of(right.reverse[0, i])]
    end
    left_offsets.merge(right_offsets)
  end

  def css_vars
    vars = WIDTHS.map { |column, width| "--#{column.to_s.dasherize}-width:#{width}px" }
    vars += left.map { |column| "--#{column.to_s.dasherize}-left:#{offsets[column]}px" }
    vars += right.map { |column| "--#{column.to_s.dasherize}-right:#{offsets[column]}px" }
    vars += ["--sticky-left-width:#{width_of(left)}px",
             "--sticky-right-width:#{width_of(right)}px"]
    vars.join(";")
  end

  private

    def width_of(columns)
      columns.sum { |column| WIDTHS.fetch(column) }
    end
end

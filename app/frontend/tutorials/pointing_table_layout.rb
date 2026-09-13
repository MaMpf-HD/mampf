# Which columns a pointing table has, in which order, which of them are pinned
# to an edge, and how wide every column is. The CSS reads widths and pins as
# variables, so a table for another kind of assessment - a talk's grade
# instead of a sheet's tasks - is one entry here and no new stylesheet.
class PointingTableLayout
  class UnsupportedAssessableError < StandardError; end

  WIDTHS = {
    team: 200,
    tutorial: 120,
    status: 170,
    task: 90,
    total: 100,
    grade: 110,
    note: 180,
    graded_by: 120,
    graded_at: 120,
    save: 90,
    hand_in: 140,
    correction: 140
  }.freeze

  # Two pins for every table: the person on the left, saving on the right;
  # everything else scrolls, so the marks get the width between them.
  def self.for(assessable:, grading_scope: nil)
    case assessable
    when Assignment
      columns = [:team]
      columns << :tutorial if grading_scope.is_a?(Lecture)
      columns += [:status, :tasks, :total, :save] if assessable.assessable?
      columns += [:hand_in, :correction]
      new(columns: columns, body: :tasks)
    when Talk
      new(columns: [:team, :status, :grade, :note, :graded_by, :graded_at, :save],
          body: :single_grade)
    else
      raise(UnsupportedAssessableError, "No pointing table layout for #{assessable.class}")
    end
  end

  attr_reader :columns, :body, :left, :right

  def initialize(columns:, body:, left: [:team], right: [:save])
    @columns = columns
    @body = body
    @left = left
    @right = right
  end

  def show?(column)
    columns.include?(column)
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

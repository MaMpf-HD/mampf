# Defines the columns, pins, and widths shared by table headers and rows.
class PointingTableLayout
  class UnsupportedAssessableError < StandardError; end

  WIDTHS = {
    team: 200,
    tutorial: 120,
    status: 170,
    status_compact: 50,
    task: 90,
    total: 100,
    talk: 200,
    grade: 110,
    note: 180,
    graded: 220,
    save: 90,
    hand_in: 140,
    correction: 140
  }.freeze

  # Pin :talk and :team so the talk and speaker remain visible while
  # scrolling through the grade and note columns. An exam has two tables,
  # one for the points and one for the grade; `table_option` picks.
  def self.for(assessable:, grading_scope: nil, table_option: :pointing)
    case assessable
    when Assignment
      columns = [:team]
      columns << :tutorial if grading_scope.is_a?(Lecture)
      columns += [:status, :tasks, :total, :save] if assessable.assessable?
      columns += [:hand_in, :correction]
      new(columns: columns, body: :tasks)
    when Talk
      new(columns: [:talk, :team, :status, :grade, :note, :graded, :save],
          body: :single_grade, left: [:talk, :team])
    when Exam
      if table_option == :grading
        new(columns: [:team, :status_compact, :total, :grade, :save], body: :single_grade)
      else
        new(columns: [:team, :status, :tasks, :total, :save], body: :tasks)
      end
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
    raise(ArgumentError, "Unknown pointing table column #{column}") unless WIDTHS.key?(column)

    css = "#{column.to_s.dasherize}-col"
    pinned?(column) ? "sticky-col #{css}" : css
  end

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

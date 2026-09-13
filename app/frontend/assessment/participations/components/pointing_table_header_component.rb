class PointingTableHeaderComponent < ViewComponent::Base
  Column = Struct.new(:css_class, :label, :sublabel, :label_hidden, keyword_init: true)

  # A heading sits the way its column's content does: text starts at the
  # left, a badge, a select or an icon stands in the middle.
  TEXT_COLUMNS = [:team, :talk, :note, :graded].freeze

  def initialize(assessable:, layout:)
    @assessable = assessable
    @layout = layout
    @assessment = assessable.assessment
    super()
  end

  # The layout names the columns; each is built from what it acts on - the
  # points, the grade, the hand-in, the correction.
  def columns
    @layout.columns.flat_map { |column| build(column) }
  end

  private

    def build(column)
      case column
      when :tasks then tasks.map { |task| task_column(task) }
      when :total then total_column
      when :save then save_column
      else plain_column(column)
      end
    end

    def tasks
      @assessment&.persisted_tasks || []
    end

    def plain_column(column)
      classes = [("text-center" unless TEXT_COLUMNS.include?(column)),
                 @layout.column_class(column), "grade-th"]
      Column.new(css_class: classes.compact.join(" "),
                 label: label_for(column),
                 sublabel: sublabel_for(column))
    end

    def label_for(column)
      case column
      when :team then team_label
      when :talk then t("basics.talk")
      when :tutorial then t("basics.tutorial")
      when :status then t("assessment.grading_tutorial.status")
      when :hand_in then t("basics.submission")
      when :correction then t("basics.correction")
      else t("assessment.grade_talk_row.#{column}")
      end
    end

    def team_label
      return t("assessment.grade_talk_row.speaker") if @assessable.is_a?(Talk)

      t("basics.team")
    end

    # Two file columns read alike; the file type tells them from the team.
    def sublabel_for(column)
      return unless [:hand_in, :correction].include?(column)

      "(#{@assessable.accepted_file_type})"
    end

    def task_column(task)
      Column.new(
        css_class: "text-center #{@layout.column_class(:task)} grade-th",
        label: "#{t("assessment.grading_tutorial.task")} #{task.position}",
        sublabel: "(#{task.max_points || 0} #{t("assessment.grading_tutorial.max_points")})"
      )
    end

    def total_column
      Column.new(
        css_class: "text-center #{@layout.column_class(:total)} grade-th",
        label: t("assessment.grading_tutorial.total_points"),
        sublabel: "(#{@assessment&.effective_total_points || 0} " \
                  "#{t("assessment.grading_tutorial.max_points")})"
      )
    end

    # Two icons need no heading over them; a reader without eyes gets one.
    def save_column
      Column.new(css_class: "text-center #{@layout.column_class(:save)} grade-th",
                 label: t("buttons.save"),
                 label_hidden: true)
    end
end

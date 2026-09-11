class PointingTableHeaderComponent < ViewComponent::Base
  Column = Struct.new(:css_class, :label, :sublabel,
                      :data_mode, :action_tag, keyword_init: true)

  def initialize(grading_scope:, # rubocop:disable Metrics/ParameterLists
                 grading_enabled:,
                 assessable_type:,
                 table_option: nil,
                 tasks: [],
                 total_max_points: 0,
                 accepted_file_type: nil,
                 tutorials: [])
    @grading_scope = grading_scope
    @grading_enabled = grading_enabled
    @assessable_type = assessable_type
    @table_option = table_option
    @tasks = tasks
    @total_max_points = total_max_points
    @accepted_file_type = accepted_file_type
    @tutorials = tutorials || []
    @status = ["all", "pending", "reviewed"]
    super()
  end

  # team is mandatory for all
  # tutorial is only for lecture scope only
  # status is only when having assessment
  # pointing_columns are only when having assessment
  # action_column is mandatory for all
  # correction_column for tutorial scope
  def assignment_columns
    [
      team_column,
      *tutorial_column,
      *status_col,
      *pointing_columns,
      *action_column,
      *correction_column
    ].compact
  end

  # team is mandatory for all
  # status is only when having assessment
  # grading_columns are only when having assessment
  # action_column is mandatory for all
  def talk_columns
    [
      team_column,
      *status_col,
      *grading_columns,
      *action_column
    ].compact
  end

  def exam_pointing_columns
    [
      team_column,
      *status_col,
      *pointing_columns,
      *action_column
    ].compact
  end

  def exam_grading_columns
    [
      team_column,
      *status_col,
      *grading_columns,
      *action_column
    ].compact
  end

  def columns
    case @assessable_type
    when "Assignment"
      assignment_columns
    when "Talk"
      talk_columns
    when "Exam"
      case @table_option
      when :pointing
        exam_pointing_columns
      when :grading
        exam_grading_columns
      end
    else
      raise(ArgumentError, "Unsupported assessable type: #{@assessable_type} ")
    end
  end

  private

    def lecture_scope?
      @grading_scope.is_a?(Lecture)
    end

    def tutorial_scope?
      @grading_scope.is_a?(Tutorial)
    end

    def team_column
      Column.new(css_class: "sticky-col team-col grade-th", label: t("basics.team"))
    end

    def tutorial_column
      return [] unless lecture_scope?

      if @tutorials&.count&.zero? || @tutorials.nil?
        [Column.new(
          css_class: "sticky-col tutorial-col grade-th text-center",
          label: t("basics.tutorial")
        )]
      else
        # need to use action_tag to identify the column for the filter dropdown
        # need to increase z-index of the header cell
        [Column.new(css_class: "sticky-col tutorial-col grade-th text-center z-20",
                    label: t("basics.tutorial"),
                    action_tag: "filter-tutorials")]
      end
    end

    def status_col
      return [] unless @grading_enabled

      [Column.new(css_class: "text-center sticky-col status-col grade-th z-10",
                  action_tag: "filter-status",
                  label: t("assessment.grading_tutorial.status"))]
    end

    def pointing_columns
      return [] unless @grading_enabled

      [
        *@tasks.map { |task| task_column(task) },
        Column.new(
          css_class: "text-center sticky-col total-col grade-th",
          label: t("assessment.grading_tutorial.total_points"),
          sublabel: "(#{@total_max_points} #{t("assessment.grading_tutorial.max_points")})"
        )
      ]
    end

    def grading_columns
      return [] unless @grading_enabled

      [
        grade_column,
        note_column,
        graded_by_column,
        graded_at_column
      ]
    end

    def task_column(task)
      Column.new(
        css_class: "text-center sticky-col task-col grade-th",
        label: "#{t("assessment.grading_tutorial.task")} #{task.position}",
        sublabel: "(#{task.max_points || 0} #{t("assessment.grading_tutorial.max_points")})"
      )
    end

    def action_column
      [Column.new(css_class: "text-center sticky-col action-col grade-th",
                  label: t("assessment.grading_tutorial.actions"))]
    end

    def correction_column
      return [] if lecture_scope?

      [Column.new(
        css_class: "text-center sticky-col correction-col grade-th",
        label: t("basics.correction"),
        sublabel: "(#{@accepted_file_type})"
      )]
    end

    def grade_column
      Column.new(css_class: "text-center sticky-col grade-col grade-th",
                 label: t("assessment.grade_talk_row.grade"))
    end

    def note_column
      Column.new(css_class: "text-center sticky-col note-col grade-th",
                 label: t("assessment.grade_talk_row.note"))
    end

    def graded_by_column
      Column.new(css_class: "text-center sticky-col graded-by-col grade-th",
                 label: t("assessment.grade_talk_row.graded_by"))
    end

    def graded_at_column
      Column.new(css_class: "text-center sticky-col graded-at-col grade-th",
                 label: t("assessment.grade_talk_row.graded_at"))
    end
end

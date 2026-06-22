class PointingTableHeaderComponent < ViewComponent::Base
  Column = Struct.new(:css_class, :label, :sublabel, keyword_init: true)

  def initialize(mode:, grading_enabled:, tasks: [], total_max_points: 0, accepted_file_type: nil)
    @mode = mode.to_sym
    @grading_enabled = grading_enabled
    @tasks = tasks
    @total_max_points = total_max_points
    @accepted_file_type = accepted_file_type
    super()
  end

  def columns
    [
      team_column,
      *tutorial_column,
      *grading_columns,
      *action_column,
      *correction_column
    ].compact
  end

  private

    def teacher?
      @mode == :teacher
    end

    def team_column
      Column.new(css_class: "sticky-col team-col grade-th", label: t("basics.team"))
    end

    def tutorial_column
      return [] unless teacher?

      [Column.new(css_class: "sticky-col tutorial-col grade-th", label: t("basics.tutorial"))]
    end

    def status_col
      if teacher?
        Column.new(css_class: "text-center sticky-col status-col-teacher grade-th",
                   label: t("assessment.grading_tutorial.status"))
      else
        Column.new(css_class: "text-center sticky-col status-col grade-th",
                   label: t("assessment.grading_tutorial.status"))
      end
    end

    def grading_columns
      return [] unless @grading_enabled

      status_col if teacher?

      [
        status_col,
        *@tasks.map { |task| task_column(task) },
        Column.new(
          css_class: "text-center sticky-col total-col grade-th",
          label: t("assessment.grading_tutorial.total_points"),
          sublabel: "(#{@total_max_points} #{t("assessment.grading_tutorial.max_points")})"
        )
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
      if teacher?
        [Column.new(css_class: "text-center sticky-col action-col-teacher grade-th",
                    label: t("assessment.grading_tutorial.actions"))]
      else
        [Column.new(css_class: "text-center sticky-col action-col grade-th",
                    label: t("assessment.grading_tutorial.actions"))]
      end
    end

    def correction_column
      return [] if teacher?

      [Column.new(
        css_class: "text-center sticky-col correction-col grade-th",
        label: t("basics.correction"),
        sublabel: "(#{@accepted_file_type})"
      )]
    end
end

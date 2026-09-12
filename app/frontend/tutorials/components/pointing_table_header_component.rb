class PointingTableHeaderComponent < ViewComponent::Base
  Column = Struct.new(:css_class, :label, :sublabel, :label_hidden, keyword_init: true)

  def initialize(grading_scope:, grading_enabled:, tasks: [], total_max_points: 0,
                 accepted_file_type: nil)
    @grading_scope = grading_scope
    @grading_enabled = grading_enabled
    @tasks = tasks
    @total_max_points = total_max_points
    @accepted_file_type = accepted_file_type
    super()
  end

  # Columns are named after what they act on: the points, the hand-in, the
  # correction. Two file columns read alike, and saving sits by the total it
  # saves.
  def columns
    [
      team_column,
      *tutorial_column,
      *grading_columns,
      hand_in_column,
      correction_column
    ].compact
  end

  private

    def lecture_scope?
      @grading_scope.is_a?(Lecture)
    end

    def team_column
      Column.new(css_class: "sticky-col team-col grade-th", label: t("basics.team"))
    end

    def tutorial_column
      return [] unless lecture_scope?

      [Column.new(css_class: "tutorial-col grade-th text-center",
                  label: t("basics.tutorial"))]
    end

    def status_col
      Column.new(css_class: "text-center status-col grade-th",
                 label: t("assessment.grading_tutorial.status"))
    end

    def grading_columns
      return [] unless @grading_enabled

      [
        status_col,
        *@tasks.map { |task| task_column(task) },
        Column.new(
          css_class: "text-center total-col grade-th",
          label: t("assessment.grading_tutorial.total_points"),
          sublabel: "(#{@total_max_points} #{t("assessment.grading_tutorial.max_points")})"
        ),
        # Two icons need no heading over them; a reader without eyes gets one.
        Column.new(css_class: "text-center sticky-col save-col grade-th",
                   label: t("buttons.save"),
                   label_hidden: true)
      ]
    end

    def task_column(task)
      Column.new(
        css_class: "text-center task-col grade-th",
        label: "#{t("assessment.grading_tutorial.task")} #{task.position}",
        sublabel: "(#{task.max_points || 0} #{t("assessment.grading_tutorial.max_points")})"
      )
    end

    def hand_in_column
      Column.new(css_class: "text-center hand-in-col grade-th",
                 label: t("basics.submission"),
                 sublabel: "(#{@accepted_file_type})")
    end

    def correction_column
      Column.new(
        css_class: "text-center correction-col grade-th",
        label: t("basics.correction"),
        sublabel: "(#{@accepted_file_type})"
      )
    end
end

class PointingTableHeaderComponent < ViewComponent::Base
  Column = Struct.new(:css_class, :label, :sublabel,
                      :data_mode, :action_tag, :label_hidden, keyword_init: true)

  def initialize(grading_scope:, # rubocop:disable Metrics/ParameterLists
                 grading_enabled:,
                 assessable_type:,
                 tasks: [],
                 total_max_points: 0,
                 accepted_file_type: nil,
                 tutorials: [],
                 status_without_hand_in: nil)
    @grading_scope = grading_scope
    @grading_enabled = grading_enabled
    @assessable_type = assessable_type
    @tasks = tasks
    @total_max_points = total_max_points
    @accepted_file_type = accepted_file_type
    @tutorials = tutorials || []
    # The filter offers the states the badge in the column can show.
    @status = ["all", "reviewed", "pending_grading",
               (status_without_hand_in || :not_submitted).to_s]
    super()
  end

  # Columns are named after what they act on: the points, the hand-in, the
  # correction. Two file columns read alike, and saving sits by the total it
  # saves.
  def assignment_columns
    [
      team_column,
      *tutorial_column,
      *status_col,
      *pointing_columns,
      *save_column,
      hand_in_column,
      *correction_column
    ].compact
  end

  # team is mandatory for all
  # status is only when having assessment
  # grading_columns are only when having assessment
  # save_column is mandatory for all
  def talk_columns
    [
      team_column,
      *status_col,
      *grading_columns,
      *save_column
    ].compact
  end

  def columns
    case @assessable_type
    when "Assignment"
      assignment_columns
    when "Talk"
      talk_columns
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
        # The tutorial dropdown must appear above the sticky status header (z-10).
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

    def save_column
      [Column.new(css_class: "text-center sticky-col save-col grade-th",
                  label: t("assessment.grading_tutorial.save"))]
    end

    def hand_in_column
      Column.new(css_class: "text-center sticky-col hand-in-col grade-th",
                 label: t("basics.submission"),
                 sublabel: "(#{@accepted_file_type})")
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

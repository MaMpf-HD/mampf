# Renders the dashboard for an assessment, which includes multiple tabs for
# different aspects of the assessment management.
class AssessmentDashboardComponent < ViewComponent::Base
  TabConfig = Data.define(:key, :label, :component)

  # rubocop: disable Metrics/ParameterLists
  def initialize(assessable:, assessment:, lecture:,
                 active_tab: nil, tasks: nil, task: nil,
                 grade_scheme: nil)
    super()
    @assessable = assessable
    @assessment = assessment
    @lecture = lecture
    @tasks = tasks || assessment&.tasks&.order(:position) || []
    @task = task
    @grade_scheme = grade_scheme
    @active_tab = normalize_tab_key(active_tab) || default_tab
  end
  # rubocop: enable Metrics/ParameterLists

  attr_reader :assessable, :assessment, :lecture, :active_tab, :tasks, :task,
              :grade_scheme

  def tabs
    @tabs ||= build_tabs
  end

  def default_tab
    if exam? || assignment?
      "settings"
    else
      "grades"
    end
  end

  def back_path
    if exam?
      helpers.exams_path(lecture_id: lecture.id)
    else
      helpers.assessment_assessments_path(lecture_id: lecture.id)
    end
  end

  def subtitle
    return unless exam?

    "#{lecture.title} · #{lecture.term_teacher_info}"
  end

  def tab_active?(key)
    active_tab == key
  end

  def dom_prefix
    @dom_prefix ||=
      "dashboard-#{assessable.class.name.downcase}-#{assessable.id}"
  end

  private

    def exam?
      assessable.is_a?(Exam)
    end

    def assignment?
      assessable.is_a?(Assignment)
    end

    def pointable?
      assessable.is_a?(Assessment::Pointable)
    end

    def gradable?
      assessable.is_a?(Assessment::Gradable)
    end

    def build_tabs
      [].tap do |t|
        t << settings_tab if exam? || assignment?
        t << registration_tab if exam? && Flipper.enabled?(:registration_campaigns)
        t << tasks_tab if pointable?
        t << points_tab if pointable?
        t << grading_tab if gradable? && pointable?
        t << grades_tab if gradable? && !pointable?
        t << statistics_tab unless assessable.is_a?(Talk)
      end
    end

    def normalize_tab_key(key)
      return nil if key.nil?
      return "grades" if key == "grade_scheme"

      key
    end

    def settings_tab
      TabConfig.new(
        "settings",
        I18n.t("basics.settings"),
        settings_component
      )
    end

    def registration_tab_label
      helpers.render(partial: "exams/registration_tab_label",
                     locals: { exam: assessable })
    end

    def settings_component
      if exam?
        PartialTabComponent.new(
          partial: "exams/settings",
          locals: { exam: assessable, lecture: lecture }
        )
      else
        PartialTabComponent.new(
          partial: "assessment/assessments/settings",
          locals: { assessment: assessment, assessable: assessable,
                    lecture: lecture }
        )
      end
    end

    def tasks_tab
      TabConfig.new(
        "tasks",
        I18n.t("assessment.tasks"),
        TasksTabComponent.new(
          assessment: assessment, assessable: assessable,
          tasks: tasks, task: task
        )
      )
    end

    def points_tab
      TabConfig.new(
        "points",
        I18n.t("assessment.points"),
        PointGridComponent.new(assessment: assessment)
      )
    end

    def grades_tab
      TabConfig.new(
        "grades",
        I18n.t("assessment.grades"),
        GradeTableComponent.new(assessment: assessment)
      )
    end

    def grading_tab
      TabConfig.new(
        "grades",
        I18n.t("assessment.grades"),
        GradingTabComponent.new(
          assessment: assessment,
          grade_scheme: grade_scheme
        )
      )
    end

    def roster_tab
      TabConfig.new(
        "roster",
        I18n.t("assessment.roster"),
        PartialTabComponent.new(
          partial: "exams/roster",
          locals: { exam: assessable }
        )
      )
    end

    def registration_tab
      TabConfig.new(
        "registration",
        registration_tab_label,
        PartialTabComponent.new(
          partial: "exams/registration",
          locals: { exam: assessable, lecture: lecture }
        )
      )
    end

    def statistics_tab
      TabConfig.new(
        "statistics",
        I18n.t("assessment.statistics"),
        StatisticsTabComponent.new(
          assessment: assessment, lecture: lecture
        )
      )
    end
end

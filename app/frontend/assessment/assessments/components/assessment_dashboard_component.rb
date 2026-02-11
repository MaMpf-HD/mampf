class AssessmentDashboardComponent < ViewComponent::Base
  # Missing top-level docstring, please formulate one yourself 😁

  # rubocop: disable Metrics/ParameterLists
  def initialize(assessable:, assessment:, lecture:,
                 active_tab: nil, tasks: nil, task: nil)
    super()
    @assessable = assessable
    @assessment = assessment
    @lecture = lecture
    @tasks = tasks || assessment&.tasks&.order(:position) || []
    @task = task
    @active_tab = active_tab || default_tab
  end
  # rubocop: enable Metrics/ParameterLists

  attr_reader :assessable, :assessment, :lecture, :active_tab, :tasks, :task

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

  def show_overview?
    exam?
  end

  def show_settings?
    exam? || assignment?
  end

  def show_tasks?
    pointable?
  end

  def show_submissions?
    pointable? && assessment&.requires_submission
  end

  def show_points?
    pointable?
  end

  def show_grades?
    gradable?
  end

  def show_roster?
    exam?
  end

  def show_statistics?
    !assessable.is_a?(Talk)
  end

  def default_tab
    if exam?
      "overview"
    elsif assignment?
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

  def tab_active?(name)
    active_tab == name
  end

  def dom_prefix
    @dom_prefix ||=
      "dashboard-#{assessable.class.name.downcase}-#{assessable.id}"
  end
end

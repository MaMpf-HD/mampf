class PointGridComponent < ViewComponent::Base
  # Missing top-level docstring, please formulate one yourself 😁

  def initialize(assessment:)
    super()
    @assessment = assessment
  end

  attr_reader :assessment

  def show_tutorial_column?
    !assessment.assessable.is_a?(Talk)
  end

  def tasks
    @tasks ||= assessment.tasks.order(:position)
  end

  def scoring_participations
    @scoring_participations ||=
      participations.where(status: [:pending, :reviewed])
                    .where.not(submitted_at: nil)
  end

  def not_submitted_participations
    @not_submitted_participations ||=
      participations.where(status: :pending, submitted_at: nil)
  end

  def absent_participations
    @absent_participations ||= participations.where(status: :absent)
  end

  def exempt_participations
    @exempt_participations ||= participations.where(status: :exempt)
  end

  def excluded_participations
    @excluded_participations ||=
      not_submitted_participations +
      participations.where(status: [:absent, :exempt]).to_a
  end

  def any_scoring?
    scoring_participations.any?
  end

  def any_excluded?
    not_submitted_participations.any? ||
      absent_participations.any? || exempt_participations.any?
  end

  def status_label(participation)
    if participation.pending? && participation.submitted_at.nil?
      I18n.t("assessment.grade_table.not_submitted")
    else
      I18n.t("assessment.grade_table.#{participation.status}")
    end
  end

  def task_points_map(participation)
    @task_points_maps ||= {}
    @task_points_maps[participation.id] ||=
      participation.task_points.index_by(&:task_id)
  end

  def points_for(participation, task)
    tp = task_points_map(participation)[task.id]
    tp&.points
  end

  def points_display(participation, task)
    pts = points_for(participation, task)
    return "—" if pts.nil?

    format_points(pts)
  end

  def total_display(participation)
    return "—" if participation.points_total.nil?

    format_points(participation.points_total)
  end

  def max_points_display(task)
    format_points(task.max_points)
  end

  def max_total
    @max_total ||= tasks.sum(:max_points)
  end

  def max_total_display
    format_points(max_total)
  end

  private

    def format_points(value)
      (value % 1).zero? ? value.to_i.to_s : value.to_s
    end

    def participations
      @participations ||= assessment
                          .assessment_participations
                          .joins(:user)
                          .includes(:user, :tutorial, task_points: :task)
                          .order(:tutorial_id, "users.name")
    end
end

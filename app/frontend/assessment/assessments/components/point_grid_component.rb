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

  def participations
    @participations ||= assessment
                        .assessment_participations
                        .joins(:user)
                        .includes(:user, :tutorial, task_points: :task)
                        .order(:tutorial_id, "users.name")
  end

  def graded_participations
    @graded_participations ||= participations.where.not(points_total: nil)
  end

  def any_graded?
    graded_participations.any?
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
end

# Progress bar under a lecture's title showing points collected out of points
# due so far (assignments not yet expired are excluded from both numbers).
class DashboardPointsProgressComponent < ViewComponent::Base
  def initialize(lecture:, user:)
    super()
    @lecture = lecture
    @user = user
  end

  attr_reader :lecture, :user

  def render?
    lecture.assignments.expired.exists? && max_points.positive?
  end

  def max_points
    @max_points ||= due_points.marked_max_for(user.id)
  end

  def points
    @points ||= record&.points_total_materialized || 0
  end

  def percentage
    @percentage ||= [(points.to_f / max_points * 100).round, 100].min
  end

  def label
    t("dashboard.points_progress.label",
      points: format_points(points),
      max: format_points(max_points),
      percentage: percentage)
  end

  private

    def record
      return @record if defined?(@record)

      @record = StudentPerformance::Record.find_by(lecture: lecture, user: user)
    end

    def due_points
      @due_points ||= StudentPerformance::DuePoints.new(lecture: lecture)
    end

    def format_points(value)
      helpers.number_with_precision(value, precision: 1,
                                           strip_insignificant_zeros: true)
    end
end

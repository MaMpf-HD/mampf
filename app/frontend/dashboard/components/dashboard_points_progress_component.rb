# The bar under a lecture's title on the dashboard, showing how many of the
# assignment points that have come up so far the student has collected.
#
# "So far" is what makes it readable at a glance: sheets whose deadline has not
# passed are left out of both numbers, so the bar answers "how am I doing"
# rather than "how much of the term is over". The fill is one colour whatever
# the score - a bar that turns red on a bad week would be a judgement, and this
# is a status.
class DashboardPointsProgressComponent < ViewComponent::Base
  def initialize(lecture:, user:)
    super()
    @lecture = lecture
    @user = user
  end

  attr_reader :lecture, :user

  # Nothing has been due yet, or nothing that was due carried points: either
  # way there is no ratio to draw.
  def render?
    lecture.assignments.expired.exists? && max_points.positive?
  end

  def max_points
    @max_points ||= due_points.max_for(user.id)
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

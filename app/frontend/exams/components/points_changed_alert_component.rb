# The line above an exam's grading table that says how many graded rows had
# their points corrected since. Always drawn, empty when there are none, so a
# row's answer can replace it either way.
class PointsChangedAlertComponent < ViewComponent::Base
  def initialize(count:)
    super()
    @count = count
  end

  def any?
    @count.positive?
  end
end

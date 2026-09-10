# One band of the dashboard's pinboard: the lectures a student holds a place
# in, their own talks, the lectures they only bookmarked.
#
# A hairline with a short label above the band is the whole separation — the
# bands are meant to read as one continuous board that names what it is showing
# as you scroll past each line, not as boxed-off panels.
#
# The label doubles as a disclosure button: a student can fold a band away, and
# the choice is remembered per browser (see the dashboard-section Stimulus
# controller), so it survives a reload and the Turbo Stream swap the semester
# picker triggers.
class DashboardSectionComponent < ViewComponent::Base
  def initialize(title:, testid:)
    super()
    @title = title
    @testid = testid
  end

  attr_reader :title, :testid

  def heading_id
    "#{testid}-heading"
  end

  # The band's cards, named so the disclosure button can point `aria-controls`
  # at them.
  def body_id
    "#{testid}-cards"
  end

  def render?
    content.present?
  end
end

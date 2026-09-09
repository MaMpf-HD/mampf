# One band of the dashboard's pinboard: the lectures a student holds a place
# in, their own talks, the lectures they only bookmarked.
#
# A hairline with a short label above the band is the whole separation — the
# bands are meant to read as one continuous board that names what it is showing
# as you scroll past each line, not as boxed-off panels.
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

  def render?
    content.present?
  end
end

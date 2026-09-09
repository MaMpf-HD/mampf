# One band of the dashboard's pinboard: the lectures a student holds a place
# in, the ones they only bookmarked, their own talks.
#
# A hairline above the band is the whole visual separation — the bands are
# meant to read as one continuous board that changes subject as you scroll,
# not as boxed-off panels. The heading that says which band this is exists for
# screen readers only, for the same reason.
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

# One collapsible band of the dashboard (registered lectures, talks,
# bookmarks), labeled with a hairline. Fold state is remembered per browser
# by the dashboard-section Stimulus controller.
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

  def body_id
    "#{testid}-cards"
  end

  def render?
    content.present?
  end
end

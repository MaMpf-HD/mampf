# Represents the overview component for assessments in the lecture.
# It manages the active tab and provides helper methods for rendering the tabs
# and their content.
class AssessmentsOverviewComponent < ViewComponent::Base
  def initialize(lecture:, active_tab: nil)
    super()
    @lecture = lecture
    tab = active_tab&.to_sym
    @active_tab = tab == :assessments ? tab : :assessments
  end

  attr_reader :lecture, :active_tab

  def tab_active?(key)
    active_tab == key
  end

  def assessments_tab_label
    I18n.t("assessment.tabs.assignments")
  end

  def single_tab?
    true
  end

  def visible_tabs
    [:assessments]
  end
end

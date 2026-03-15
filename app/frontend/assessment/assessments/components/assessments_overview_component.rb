# Renders an overview of assessments with tabs for assessments, achievements,
# performance, and certifications.
class AssessmentsOverviewComponent < ViewComponent::Base
  TABS = [:assessments, :achievements, :performance,
          :certifications].freeze

  def initialize(lecture:, active_tab: nil)
    super()
    @lecture = lecture
    @active_tab = resolve_tab(active_tab)
  end

  attr_reader :lecture, :active_tab

  def tab_active?(key)
    active_tab == key
  end

  def assessments_tab_label
    if lecture.seminar?
      I18n.t("assessment.tabs.talks")
    else
      I18n.t("assessment.tabs.assignments")
    end
  end

  def performance_enabled?
    Flipper.enabled?(:student_performance)
  end

  def achievements_enabled?
    Flipper.enabled?(:student_performance)
  end

  def certifications_enabled?
    Flipper.enabled?(:student_performance)
  end

  def visible_tabs
    tabs = [:assessments]
    tabs << :achievements if achievements_enabled?
    tabs << :performance if performance_enabled?
    tabs << :certifications if certifications_enabled?
    tabs
  end

  private

    def resolve_tab(tab)
      key = tab&.to_sym
      return key if key.in?(visible_tabs)

      :assessments
    end
end

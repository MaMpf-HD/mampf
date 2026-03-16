# Renders an overview of assessments, including tabs for performance and rules.
class AssessmentsOverviewComponent < ViewComponent::Base
  TABS = [:assessments, :performance, :rules, :certifications].freeze

  def initialize(lecture:, active_tab: nil)
    super()
    @lecture = lecture
    @active_tab = resolve_tab(active_tab)
  end

  attr_reader :lecture, :active_tab

  def tab_active?(key)
    active_tab == key
  end

  def performance_enabled?
    Flipper.enabled?(:student_performance)
  end

  def rules_enabled?
    Flipper.enabled?(:student_performance)
  end

  def certifications_enabled?
    Flipper.enabled?(:student_performance)
  end

  def visible_tabs
    tabs = [:assessments]
    tabs << :performance if performance_enabled?
    tabs << :rules if rules_enabled?
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

# Missing top-level docstring, please formulate one yourself 😁
class AchievementDashboardComponent < ViewComponent::Base
  TabConfig = Data.define(:key, :label, :component)

  def initialize(achievement:, lecture:, active_tab: nil)
    super()
    @achievement = achievement
    @lecture = lecture
    @active_tab = active_tab || "settings"
  end

  attr_reader :achievement, :lecture, :active_tab, :back_path

  def before_render
    @back_path = helpers.assessment_assessments_path(
      lecture_id: lecture.id, tab: "achievements"
    )
  end

  def dom_prefix
    @dom_prefix ||= "dashboard-achievement-#{achievement.id}"
  end

  def tab_active?(key)
    active_tab == key
  end

  def tabs
    @tabs ||= build_tabs
  end

  private

    def build_tabs
      [].tap do |t|
        t << settings_tab
        t << marking_tab if grading_enabled?
      end
    end

    def grading_enabled?
      Flipper.enabled?(:assessment_grading) && achievement.assessment.present?
    end

    def settings_tab
      TabConfig.new(
        key: "settings",
        label: I18n.t("basics.settings"),
        component: PartialTabComponent.new(
          partial: "student_performance/achievements/settings",
          locals: { achievement: achievement, lecture: lecture }
        )
      )
    end

    def marking_tab
      TabConfig.new(
        key: "marking",
        label: I18n.t("assessment.grading"),
        component: AchievementMarkingTableComponent.new(
          achievement: achievement
        )
      )
    end
end

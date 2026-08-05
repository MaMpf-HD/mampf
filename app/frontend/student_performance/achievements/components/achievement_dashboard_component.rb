# Missing top-level docstring, please formulate one yourself 😁
class AchievementDashboardComponent < ViewComponent::Base
  def initialize(achievement:, lecture:, original_achievement: achievement)
    super()
    @achievement = achievement
    @lecture = lecture
    @original_achievement = original_achievement
  end

  attr_reader :achievement, :lecture, :original_achievement, :back_path

  def before_render
    @back_path = helpers.assessment_assessments_path(
      lecture_id: lecture.id, tab: "achievements"
    )
  end

  def dom_prefix
    @dom_prefix ||= "dashboard-achievement-#{achievement.id}"
  end

  def grading_enabled?
    Flipper.enabled?(:assessment_grading) && achievement.assessment.present?
  end
end

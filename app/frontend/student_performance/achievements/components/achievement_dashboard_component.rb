# Missing top-level docstring, please formulate one yourself 😁
class AchievementDashboardComponent < ViewComponent::Base
  def initialize(achievement:, lecture:)
    super()
    @achievement = achievement
    @lecture = lecture
  end

  attr_reader :achievement, :lecture, :back_path

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

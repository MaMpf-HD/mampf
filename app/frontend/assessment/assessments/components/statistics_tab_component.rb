class StatisticsTabComponent < ViewComponent::Base
  def initialize(assessment:, lecture:)
    super()
    @assessment = assessment
    @lecture = lecture
  end

  attr_reader :assessment, :lecture

  def show_submissions?
    assessment&.requires_submission
  end
end

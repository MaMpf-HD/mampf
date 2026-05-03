class StatisticsTabComponent < ViewComponent::Base
  # Missing top-level docstring, please formulate one yourself 😁

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

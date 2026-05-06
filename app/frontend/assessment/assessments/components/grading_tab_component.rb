# Missing top-level docstring, please formulate one yourself 😁
class GradingTabComponent < ViewComponent::Base
  def initialize(assessment:)
    super()
    @assessment = assessment
  end

  attr_reader :assessment
end
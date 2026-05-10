class TutorialGradingTableComponent < ViewComponent::Base
  def initialize(assignment:, tutorial:, stack:)
    super()
    @assignment = assignment
    @tutorial = tutorial
    @stack = stack
  end

  def grading_enabled?
    @assignment.assessment.present?
  end

  def tasks
    @assignment.assessment.tasks
  end
end

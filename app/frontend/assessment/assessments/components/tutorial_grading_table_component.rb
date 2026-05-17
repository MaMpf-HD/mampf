class TutorialGradingTableComponent < ViewComponent::Base
  def initialize(assignment:, tutorial:, stack:, non_submitters:)
    super()
    @assignment = assignment
    @tutorial = tutorial
    @stack = stack
    @non_submitters = non_submitters
  end

  def grading_enabled?
    @assignment.assessment.present?
  end

  def tasks
    @assignment.assessment.tasks
  end
end

class TutorialGradingTableComponent < ViewComponent::Base
  def initialize(assignment:, tutorial:, stack:, non_submitters:)
    super()
    @assignment = assignment
    @tutorial = tutorial
    @stack = stack
    @non_submitters = non_submitters
  end

  def grading_enabled?
    Flipper.enabled?(:assessment_grading) && @assignment.assessable?
  end

  def tasks
    @assignment.assessment.tasks
  end

  def total_max_points
    tasks.filter_map(&:max_points).sum
  end
end

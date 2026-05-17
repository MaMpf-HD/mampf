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

  def non_submitters
    @non_submitters ||= @tutorial.tutorial_memberships
                                 .joins(:user)
                                 .order("users.name")
                                 .map(&:user)
                                 .reject { |u| u.in?(@assignment.submitters) }
  end

  def has_non_submitters?
    non_submitters.any?
  end
end

class TasksTabComponent < ViewComponent::Base
  # Missing top-level docstring, please formulate one yourself 😁

  def initialize(assessment:, assessable:, tasks:, task:)
    super()
    @assessment = assessment
    @assessable = assessable
    @tasks = tasks
    @task = task
  end

  attr_reader :assessment, :assessable, :tasks, :task
end

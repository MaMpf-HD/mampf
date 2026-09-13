# The filters above a pointing table - a name, a state, on the lecture's
# table a group - with the reset and the count that appear once one is set.
# What the strip carries on its right - actions, saving - comes as content.
class PointingFilterComponent < ViewComponent::Base
  def initialize(id:, status_options: nil, tutorial_options: nil)
    super()
    @id = id
    @status_options = status_options
    @tutorial_options = tutorial_options
  end

  def status_filter?
    @status_options.present?
  end

  def tutorial_filter?
    @tutorial_options.present?
  end
end

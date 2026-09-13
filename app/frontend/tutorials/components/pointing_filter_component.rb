# The filters above a pointing table, the same for a sheet's and a talk's;
# whatever sits on the right - actions, saving - comes as content.
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

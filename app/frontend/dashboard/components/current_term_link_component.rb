# Link next to the dashboard's term picker that switches it back to the
# current (active) term. Shown whenever another term is selected.
class CurrentTermLinkComponent < ViewComponent::Base
  def initialize(selected:, anchor: nil)
    super()
    @selected = selected
    @anchor = anchor
  end

  def render?
    current_term.present? && @selected.present? && @selected != current_term
  end

  def current_term
    return @current_term if defined?(@current_term)

    @current_term = Term.active
  end

  def target_path
    root_path(term: current_term.dashboard_param, anchor: @anchor)
  end
end

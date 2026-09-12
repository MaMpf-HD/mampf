class DashboardTermSelectComponent < ViewComponent::Base
  def initialize(terms:, selected:, id:, anchor: nil)
    super()
    @terms = terms
    @selected = selected
    @id = id
    @anchor = anchor
  end

  attr_reader :terms, :selected, :id, :anchor

  def render?
    # Nothing to pick from if there's only one term
    terms.size > 1 && selected.present?
  end

  def options
    terms.reverse.map do |term|
      [term.to_label, term.dashboard_param, { data: { url: target_path(term) } }]
    end
  end

  def target_path(term)
    root_path(term: term.dashboard_param, anchor: anchor)
  end
end

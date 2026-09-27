class DashboardTermSelectComponent < ViewComponent::Base
  def initialize(terms:, selected:, id:, next_term_lecture_count:, anchor: nil)
    super()
    @terms = terms
    @selected = selected
    @id = id
    @next_term_lecture_count = next_term_lecture_count
    @anchor = anchor
  end

  attr_reader :terms, :selected, :id, :next_term_lecture_count, :anchor

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

  def active_term
    return @active_term if defined?(@active_term)

    @active_term = Term.active
  end

  def next_term
    return @next_term if defined?(@next_term)

    @next_term = active_term&.next
  end

  # See Dashboard::TermSelector.next_term_lecture_count for what's counted.
  def show_next_term_notice?
    selected == active_term && next_term.present? &&
      next_term_lecture_count.positive?
  end

  def show_current_term_link?
    active_term.present? && selected != active_term
  end

  # Without an anchor, the picker sits on the dashboard and the link jumps down
  # to the lecture search. With one, the picker is already in the search.
  def next_term_link_data
    data = { testid: "next-term-notice-link" }
    anchor.present? ? data.merge(pick_data(next_term)) : data
  end

  def pick_data(term)
    { action: "dashboard-term-select#pick",
      dashboard_term_select_term_param: term.dashboard_param }
  end
end

# A plain semester picker for the dashboard: a `<select>` of every semester
# that, on change, refreshes the dashboard sections and the lecture search for
# that term in place (Turbo Stream), with the URL set to `/?term=<slug>`.
#
# The page shows two copies — one at the top, one just above the search bar —
# both server-rendered from the same selected term, so they stay in sync. The
# copy above the search passes `anchor: "lecture-search"` so its Turbo visit
# keeps the search in view.
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
    # Nothing to pick from with a single semester.
    terms.size > 1 && selected.present?
  end

  # Newest first: a student changing semester is far likelier to be heading
  # into the upcoming term than digging into the past.
  #
  # The terse form ("SS 2026", "WS 2025/26") rather than the spelled-out one:
  # every option then starts with a two-letter season, so the years line up in
  # a column and the list can be read down instead of word by word. The word
  # "Semester" is said once, by the label in front of the select, and would
  # only be noise repeated in each option.
  def options
    terms.reverse.map { |term| [term.to_label, target_path(term)] }
  end

  def target_path(term)
    root_path(term: term.dashboard_param, anchor: anchor)
  end
end

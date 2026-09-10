# A plain semester picker for the dashboard: a `<select>` of every semester
# that, on change, does a Turbo visit to `/?term=<id>` and re-renders the
# dashboard sections and the lecture search for that term.
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
  def options
    terms.reverse.map { |term| [term.to_long_label, target_path(term)] }
  end

  def target_path(term)
    root_path(term: term.id, anchor: anchor)
  end
end

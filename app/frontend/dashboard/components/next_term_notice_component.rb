# Small hint next to the dashboard's term picker, pointing to the lectures
# already published for the upcoming term. Shown only once at least one
# lecture of that term is published and the dashboard doesn't already show
# that term. The count also includes term-independent lectures, since the
# search the hint links to lists them as well.
#
# With in_search: true, the hint sits next to the lecture search's own picker:
# its link then just switches the picker to the upcoming term instead of
# jumping down to the search.
class NextTermNoticeComponent < ViewComponent::Base
  def initialize(selected:, in_search: false)
    super()
    @selected = selected
    @in_search = in_search
  end

  attr_reader :in_search

  def render?
    next_term.present? && next_term != @selected &&
      Lecture.published.exists?(term: next_term)
  end

  def next_term
    return @next_term if defined?(@next_term)

    @next_term = Term.active&.next
  end

  def lecture_count
    @lecture_count ||= Lecture.published.where(term: [next_term, nil]).count
  end

  def target_path
    root_path(term: next_term.dashboard_param, anchor: "lecture-search")
  end

  def link_data
    data = { testid: "next-term-notice-link" }
    return data unless in_search

    data.merge(action: "dashboard-term-select#pick",
               dashboard_term_select_term_param: next_term.dashboard_param)
  end
end

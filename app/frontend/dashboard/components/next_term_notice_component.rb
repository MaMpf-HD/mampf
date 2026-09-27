# Small hint next to the dashboard's term picker, pointing to the lectures
# already published for the upcoming term. Shown only once at least one
# lecture of that term is published and the dashboard doesn't already show
# that term. The count also includes term-independent lectures, since the
# search the hint links to lists them as well.
class NextTermNoticeComponent < ViewComponent::Base
  def initialize(selected:)
    super()
    @selected = selected
  end

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
end

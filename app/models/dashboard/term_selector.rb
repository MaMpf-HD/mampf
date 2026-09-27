module Dashboard
  class TermSelector
    def self.terms
      Term.chronological.to_a
    end

    def self.selected(params)
      Term.from_dashboard_param(params[:term]) || Term.active
    end

    # Matches what the lecture search shows for the next term, i.e. includes
    # term-independent lectures (see Search::Filters::DashboardTermFilter).
    # Zero unless the next term has lectures of its own, as term-independent
    # lectures show up in every term anyway.
    def self.next_term_lecture_count
      next_term = Term.active&.next
      return 0 if next_term.blank?
      return 0 unless Lecture.published.exists?(term: next_term)

      Lecture.published.where(term: [next_term, nil]).count
    end
  end
end

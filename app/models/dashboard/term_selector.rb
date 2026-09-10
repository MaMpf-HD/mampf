module Dashboard
  # The list of semesters the dashboard's semester picker offers, and the rule
  # for which one a given request is scoped to.
  #
  # The dashboard sections and the lecture search below them both scope to
  # `selected`, so that picking a semester moves the whole page to that
  # semester in one Turbo visit.
  class TermSelector
    # Every term there is, oldest first.
    def self.terms
      Term.chronological.to_a
    end

    # The term this request is scoped to: an explicit `?term=<slug>` (see
    # Term#dashboard_param), the legacy `?term_scope=current|next` that a few
    # deep links still use, or, failing both, the active term.
    def self.selected(params)
      Term.from_dashboard_param(params[:term]) ||
        by_scope(params[:term_scope]) ||
        Term.active
    end

    def self.by_scope(scope)
      case scope
      when "current" then Term.active
      when "next" then Term.active&.next
      end
    end
    private_class_method :by_scope
  end
end

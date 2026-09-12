module Dashboard
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

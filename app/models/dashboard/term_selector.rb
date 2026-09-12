module Dashboard
  class TermSelector
    # Every term there is, oldest first.
    def self.terms
      Term.chronological.to_a
    end

    # The currently selected term.
    def self.selected(params)
      Term.from_dashboard_param(params[:term]) || Term.active
    end
  end
end

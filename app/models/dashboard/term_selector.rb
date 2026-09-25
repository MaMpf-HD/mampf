module Dashboard
  class TermSelector
    def self.terms
      Term.chronological.to_a
    end

    def self.selected(params)
      Term.from_dashboard_param(params[:term]) || Term.active
    end
  end
end

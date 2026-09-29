module Search
  module Filters
    # Scopes the dashboard's lecture search to the semester picked in
    # `search[term]` (see Term#dashboard_param), falling back to the active
    # term. Term-independent lectures (term: nil) are always kept in.
    # `search[all_terms]` lifts the scope for one search without changing the
    # picked semester.
    class DashboardTermFilter < BaseFilter
      def filter
        return scope if params[:all_terms] == "1"
        return scope if params[:term].blank? && Term.active.blank?

        term = Term.from_dashboard_param(params[:term]) || Term.active
        return scope.where(term: nil) if term.blank?

        scope.where(term: [term, nil])
      end
    end
  end
end

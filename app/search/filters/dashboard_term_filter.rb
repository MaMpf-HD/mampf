module Search
  module Filters
    # Scopes the dashboard's lecture search to the semester the picker is
    # pointing at: `search[term]` carries its slug (see Term#dashboard_param),
    # server-rendered next to the dashboard so the two always agree. With no
    # value it falls back to the active term, so the search shows one semester
    # at a time rather than everything.
    #
    # Term-independent lectures (term: nil, e.g. the helpdesk) belong to every
    # semester and are always kept in.
    #
    # If there is neither an id nor an active term to fall back to (only really
    # the case in tests and a fresh install), the filter steps aside and leaves
    # the scope untouched.
    class DashboardTermFilter < BaseFilter
      def filter
        return scope if params[:term].blank? && Term.active.blank?

        term = Term.from_dashboard_param(params[:term]) || Term.active
        return scope.where(term: nil) if term.blank?

        scope.where(term: [term, nil])
      end
    end
  end
end

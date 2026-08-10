module Search
  module Filters
    class CurrentNextTermFilter < BaseFilter
      def filter
        case params[:term_scope]
        when "current"
          filter_by_term(Term.active)
        when "next"
          filter_by_term(Term.active&.next)
        else
          scope
        end
      end

      private

        def filter_by_term(term)
          # nil is used to represent term-independent lectures (e.g. helpdesk),
          # which should always be included in the results.
          return scope.where(term: nil) if term.blank?

          scope.where(term: [term, nil])
        end
    end
  end
end

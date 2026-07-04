module Search
  module Filters
    class SemesterFilter < BaseFilter
      def filter
        case params[:semester]
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
          return scope.none if term.blank?

          scope.where(term: term)
        end
    end
  end
end

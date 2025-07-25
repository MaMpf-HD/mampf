module Search
  class TermIndependenceFilter < BaseFilter
    def call
      return scope unless params[:term_independent] == "1"

      scope.where(term_independent: true)
    end
  end
end

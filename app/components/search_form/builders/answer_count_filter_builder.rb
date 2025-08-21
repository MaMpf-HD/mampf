module SearchForm
  module Builders
    class AnswerCountFilterBuilder
      def initialize(form_state, purpose: "media")
        @form_state = form_state
        @filter = Filters::AnswerCountFilter.new(purpose: purpose)
        @filter.form_state = form_state
      end

      def build
        @filter
      end
    end
  end
end

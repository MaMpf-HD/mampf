module SearchForm
  module Builders
    class MediumTypeFilterBuilder
      def initialize(form_state, purpose: "media")
        @form_state = form_state
        @filter = Filters::MediumTypeFilter.new(purpose: purpose)
        @filter.form_state = form_state
      end

      def build
        @filter
      end
    end
  end
end

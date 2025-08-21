module SearchForm
  module Builders
    class FulltextFilterBuilder
      def initialize(form_state)
        @form_state = form_state
        @filter = Filters::FulltextFilter.new
        @filter.form_state = form_state
      end

      def build
        @filter
      end
    end
  end
end

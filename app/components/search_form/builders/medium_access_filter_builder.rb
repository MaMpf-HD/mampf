module SearchForm
  module Builders
    class MediumAccessFilterBuilder
      def initialize(form_state)
        @form_state = form_state
        @filter = Filters::MediumAccessFilter.new
        @filter.form_state = form_state
      end

      def build
        @filter
      end
    end
  end
end

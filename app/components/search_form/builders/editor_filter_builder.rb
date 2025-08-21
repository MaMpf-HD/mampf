module SearchForm
  module Builders
    class EditorFilterBuilder
      def initialize(form_state)
        @form_state = form_state
        @filter = Filters::EditorFilter.new
        @filter.form_state = form_state
      end

      def build
        @filter
      end
    end
  end
end

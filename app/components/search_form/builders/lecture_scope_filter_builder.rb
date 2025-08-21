module SearchForm
  module Builders
    class LectureScopeFilterBuilder
      def initialize(form_state)
        @form_state = form_state
        @filter = Filters::LectureScopeFilter.new
        @filter.form_state = form_state
      end

      def with_lecture_options
        @filter.with_lecture_options
        self
      end

      def build
        @filter
      end
    end
  end
end

module SearchForm
  module Builders
    class LectureScopeFilterBuilder
      # Interface documentation: Available configuration methods for LectureScopeFilter
      # - with_lecture_options: Adds lecture options radio group
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

module SearchForm
  module Builders
    class TeachableFilterBuilder
      # Interface documentation: Available configuration methods for TeachableFilter
      # - with_inheritance_radios: Adds inheritance radio group
      def initialize(form_state)
        @form_state = form_state
        @filter = Filters::TeachableFilter.new
        @filter.form_state = form_state
      end

      def with_inheritance_radios
        @filter.with_inheritance_radios
        self
      end

      def build
        @filter
      end
    end
  end
end

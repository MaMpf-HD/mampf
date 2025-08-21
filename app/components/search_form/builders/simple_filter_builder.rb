module SearchForm
  module Builders
    class SimpleFilterBuilder
      def initialize(form_state, filter_class, **options)
        @form_state = form_state
        @filter = if options.any?
          filter_class.new(**options)
        else
          filter_class.new
        end
        @filter.form_state = form_state
      end

      def build
        @filter
      end
    end
  end
end

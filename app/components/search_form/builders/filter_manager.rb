module SearchForm
  module Builders
    class FilterManager
      def initialize(form_state)
        @form_state = form_state
      end

      def build_simple_filter(filter_name, **)
        filter_class = "SearchForm::Filters::#{filter_name.camelize}Filter".constantize
        builder = SimpleFilterBuilder.new(@form_state, filter_class, **)
        builder.build
      end

      def create_complex_filter_builder(filter_name, **options)
        builder_class = "SearchForm::Builders::#{filter_name.camelize}FilterBuilder".constantize
        if options.any?
          builder_class.new(@form_state, **options)
        else
          builder_class.new(@form_state)
        end
      end
    end
  end
end

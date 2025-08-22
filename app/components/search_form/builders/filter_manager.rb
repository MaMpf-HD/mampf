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

      def create_dynamic_filter_builder(filter_name, config, **)
        DynamicFilterBuilder.new(@form_state, filter_name, config, **)
      end
    end
  end
end

# app/components/search_form/builders/tag_filter_builder.rb
module SearchForm
  module Builders
    class TagFilterBuilder
      def initialize(form_state)
        @form_state = form_state
        @filter = Filters::TagFilter.new
        @filter.form_state = form_state
      end

      def with_ajax(model: "tag", locale: nil, no_results: nil)
        locale ||= I18n.locale
        no_results ||= I18n.t("basics.no_results")

        @filter.options[:data].merge!(
          model: model,
          locale: locale,
          no_results: no_results
        )
        self
      end

      def with_operator_radios
        @filter.with_operator_radios
        self
      end

      def build
        @filter
      end
    end
  end
end

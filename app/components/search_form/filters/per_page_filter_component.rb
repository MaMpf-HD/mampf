# app/components/search/filters/per_page_filter_component.rb
module SearchForm
  module Filters
    class PerPageFilterComponent < SearchForm::Select
      def initialize(id: nil, per_options: [[10, 10], [20, 20], [50, 50]], default: 10)
        super(
          name: :per,
          label: I18n.t("basics.hits_per_page"),
          collection: options_for_select(per_options, default),
          id: id || "per_page_select"
        )
      end
    end
  end
end

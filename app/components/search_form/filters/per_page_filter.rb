module SearchForm
  module Filters
    class PerPageFilter < Fields::SelectField
      def initialize(per_options: [[10, 10], [20, 20], [50, 50]], default: 10, **)
        super(
          name: :per,
          label: I18n.t("basics.hits_per_page"),
          collection: options_for_select(per_options, default),
          **
        )
      end
    end
  end
end

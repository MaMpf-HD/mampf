module SearchForm
  module Filters
    class TermIndependenceFilter < Fields::CheckboxField
      def initialize(**)
        super(
          name: :term_independent,
          label: I18n.t("admin.course.term_independent"),
          checked: false,
          **
        )
      end
    end
  end
end

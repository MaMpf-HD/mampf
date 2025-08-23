module SearchForm
  module Filters
    class TermFilter < Fields::MultiSelectField
      def initialize(**)
        super(
          name: :term_ids,
          label: I18n.t("basics.term"),
          help_text: I18n.t("admin.lecture.info.search_term"),
          collection: Term.select_terms,
          **
        )
      end
    end
  end
end

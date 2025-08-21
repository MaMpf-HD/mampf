module SearchForm
  module Filters
    class TermFilter < Fields::MultiSelectField
      def initialize(**options)
        super(
          name: :term_ids,
          label: I18n.t("basics.term"),
          help_text: I18n.t("admin.lecture.info.search_term"),
          collection: Term.select_terms,
          id: "termSearch",
          **options.reverse_merge(prompt: I18n.t("basics.select"))
        )
      end
    end
  end
end

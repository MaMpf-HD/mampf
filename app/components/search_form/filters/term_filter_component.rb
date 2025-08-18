module SearchForm
  module Filters
    class TermFilterComponent < SearchForm::MultiSelectComponent
      def initialize(**options)
        super(
          name: :term_ids,
          label: I18n.t("basics.term"),
          help_text: I18n.t("admin.lecture.info.search_term"),
          collection: Term.select_terms,
          all_toggle_name: :all_terms,
          column_class: "col-6 col-lg-3",
          id: "termSearch",
          **options.reverse_merge(prompt: I18n.t("basics.select"))
        )
      end
    end
  end
end

module SearchForm
  module Filters
    class TypesFilterComponent < SearchForm::MultiSelectComponent
      def initialize(**)
        super(
          name: :types,
          label: I18n.t("basics.type"),
          help_text: I18n.t("admin.lecture.info.search_type"),
          collection: Lecture.select_sorts,
          all_toggle_name: :all_types,
          column_class: "col-6 col-lg-3",
          **
        )
      end
    end
  end
end

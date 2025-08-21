module SearchForm
  module Filters
    class LectureTypeFilter < Fields::MultiSelectField
      def initialize(**)
        super(
          name: :types,
          label: I18n.t("basics.type"),
          help_text: I18n.t("admin.lecture.info.search_type"),
          collection: Lecture.select_sorts,
          **
        )
      end
    end
  end
end

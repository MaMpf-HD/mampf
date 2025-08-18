module SearchForm
  module Filters
    class FulltextFilterComponent < SearchForm::TextField
      def initialize(**)
        super(
          name: :fulltext,
          label: I18n.t("basics.fulltext"),
          help_text: I18n.t("admin.lecture.info.search_fulltext"),
          **
        )
      end
    end
  end
end

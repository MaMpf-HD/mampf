module SearchForm
  module Filters
    class EditorFilter < Fields::MultiSelectField
      def initialize(**)
        super(
          name: :editor_ids,
          label: I18n.t("basics.editors"),
          help_text: I18n.t("admin.lecture.info.search_teacher"),
          collection: User.select_teachers,
          **
        )
      end
    end
  end
end

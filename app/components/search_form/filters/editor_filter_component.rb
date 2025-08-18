module SearchForm
  module Filters
    class EditorFilterComponent < SearchForm::MultiSelect
      def initialize(**)
        super(
          name: :editor_ids,
          label: I18n.t("basics.editors"),
          help_text: I18n.t("admin.lecture.info.search_teacher"),
          collection: User.select_teachers,
          all_toggle_name: :all_editors,
          **
        )
      end
    end
  end
end

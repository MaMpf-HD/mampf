module SearchForm
  module Filters
    class TeacherFilterComponent < SearchForm::MultiSelect
      def initialize(**)
        super(
          name: :teacher_ids,
          label: I18n.t("basics.teachers"),
          help_text: I18n.t("admin.lecture.info.search_teacher"),
          collection: User.select_teachers,
          all_toggle_name: :all_teachers,
          column_class: "col-6 col-lg-3",
          **
        )
      end
    end
  end
end

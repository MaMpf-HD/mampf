module SearchForm
  module Filters
    class TeacherFilter < Fields::MultiSelectField
      def initialize(**)
        super(
          name: :teacher_ids,
          label: I18n.t("basics.teachers"),
          help_text: I18n.t("admin.lecture.info.search_teacher"),
          collection: User.select_teachers,
          **
        )
      end
    end
  end
end

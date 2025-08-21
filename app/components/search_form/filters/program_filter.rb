module SearchForm
  module Filters
    class ProgramFilter < Fields::MultiSelectField
      def initialize(**)
        super(
          name: :program_ids,
          label: I18n.t("basics.programs"),
          help_text: I18n.t("admin.lecture.info.search_program"),
          collection: Program.select_programs,
          **
        )
      end
    end
  end
end

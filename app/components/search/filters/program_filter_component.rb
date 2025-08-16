module Search
  module Filters
    class ProgramFilterComponent < Search::MultiSelectComponent
      def initialize(**)
        super(
          name: :program_ids,
          label: I18n.t("basics.programs"),
          help_text: I18n.t("admin.lecture.info.search_program"),
          collection: Program.select_programs,
          all_toggle_name: :all_programs,
          context: context,
          **
        )
      end
    end
  end
end

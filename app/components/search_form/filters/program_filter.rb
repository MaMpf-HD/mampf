module SearchForm
  module Filters
    class ProgramFilter < Fields::MultiSelectField
      def initialize(**)
        super(
          name: :program_ids,
          label: I18n.t("basics.programs"),
          help_text: I18n.t("admin.lecture.info.search_program"),
          collection: program_options,
          **
        )
      end

      private

        def program_options
          Program.includes(:subject, :translations, subject: :translations)
                 .map { |p| [p.name_with_subject, p.id] }
                 .natural_sort_by(&:first)
        end
    end
  end
end

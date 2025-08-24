module SearchForm
  module Filters
    class EditorFilter < Fields::MultiSelectField
      def initialize(**)
        super(
          name: :editor_ids,
          label: I18n.t("basics.editors"),
          help_text: I18n.t("admin.lecture.info.search_teacher"),
          collection: editor_options,
          **
        )
      end

      private

        def editor_options
          User.joins(:editable_user_joins)
              .distinct
              .pluck(:id, :name, :name_in_tutorials, :email)
              .map do |id, name, name_in_tutorials, email|
                display_name = "#{name_in_tutorials.presence || name} (#{email})"
                [display_name, id]
              end
              .natural_sort_by(&:first)
        end
    end
  end
end

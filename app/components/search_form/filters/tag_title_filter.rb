module SearchForm
  module Filters
    class TagTitleFilter < Fields::TextField
      def initialize(**)
        super(
          name: :title,
          label: I18n.t("basics.title"),
          help_text: I18n.t("admin.tag.info.search_title"),
          **
        )
      end
    end
  end
end

module SearchForm
  module Filters
    class TagTitleFilter < Fields::TextField
      def initialize(**options)
        super(
          name: :title,
          label: I18n.t("basics.title"),
          help_text: I18n.t("admin.tag.info.search_title"),
          placeholder: options[:placeholder] || I18n.t("search.tag_title"),
          **options
        )
      end
    end
  end
end

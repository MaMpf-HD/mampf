# app/components/search/filters/tag_title_filter_component.rb
module Search
  module Filters
    class TagTitleFilterComponent < Search::TextFieldComponent
      def initialize(placeholder: nil)
        super(
          name: :title,
          label: I18n.t("basics.title"),
          help_text: I18n.t("admin.tag.info.search_title"),
          placeholder: placeholder || I18n.t("search.tag_title")
        )
      end
    end
  end
end

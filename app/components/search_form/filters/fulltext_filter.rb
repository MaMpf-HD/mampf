# frozen_string_literal: true

module SearchForm
  module Filters
    # Fulltext search filter for keyword-based searching
    #
    # This filter provides a text input field for fulltext search queries.
    # Users can enter keywords, phrases, or search terms that will be used
    # to search across relevant text fields in the target content.
    #
    # Features:
    # - Single-line text input for search terms
    # - Internationalized labels and help text
    # - Commonly used for searching lecture content, descriptions, titles
    # - Integrates with search engines or database fulltext search
    #
    # @example Basic fulltext filter
    #   add_fulltext_filter
    #
    # @example Fulltext filter with custom prompt
    #   add_fulltext_filter(prompt: "Enter search keywords...")
    #
    # The search terms entered here are typically used with database
    # fulltext search capabilities or external search engines like Solr.
    class FulltextFilter < Fields::TextField
      def initialize(**)
        super(
          name: :fulltext,
          label: I18n.t("basics.fulltext"),
          help_text: I18n.t("admin.lecture.info.search_fulltext"),
          **
        )
      end
    end
  end
end

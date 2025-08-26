module SearchForm
  module Filters
    # Renders a text input field specifically for full-text search.
    # This component is a simple specialization of `TextField`, pre-configured
    # with a specific name, label, and help text suitable for a full-text
    # search query.
    class FulltextFilter < Fields::TextField
      # Initializes the FulltextFilter.
      #
      # This component is specialized and hard-codes its own options for the
      # underlying `TextField`, such as `:name`, `:label`, and `:help_text`.
      #
      # @param ** [Hash] Catches any other keyword arguments, which are passed
      #   to the superclass (`TextField`). This can be used to pass options like
      #   `:placeholder` or `:container_class`.
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

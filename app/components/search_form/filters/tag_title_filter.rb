module SearchForm
  module Filters
    # Renders a text input field specifically for searching by tag title.
    # This component is a simple specialization of `TextField`, pre-configured
    # with a specific name, label, and help text suitable for a tag title
    # search query.
    class TagTitleFilter < Fields::TextField
      # Initializes the TagTitleFilter.
      #
      # This component is specialized and hard-codes its own options for the
      # underlying `TextField`, such as `:name`, `:label`, and `:help_text`.
      #
      # @param ** [Hash] Catches any other keyword arguments, which are passed
      #   to the superclass (`TextField`). This can be used to pass options like
      #   `:placeholder` or `:container_class`.
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

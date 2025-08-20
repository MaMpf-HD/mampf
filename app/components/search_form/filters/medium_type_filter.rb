# app/components/search_form/filters/medium_type_filter.rb
module SearchForm
  module Filters
    class MediumTypeFilter < Fields::MultiSelectField
      def initialize(purpose: "media", **)
        super(
          name: :types,
          label: I18n.t("basics.types"), # Plural for media
          help_text: I18n.t("search.media.type"),
          collection: add_prompt(Medium.select_generic),
          all_toggle_name: :all_types,
          column_class: "col-6 col-lg-4",
          **
        )

        # Additional media-specific options
        @purpose = purpose

        # Update options based on purpose
        @options[:multiple] = purpose.in?(["media", "import"])
        @options[:disabled] = purpose == "media"
        @options[:id] = "search_media_types"

        # Use helpers to properly initialize selected values
        @selected_value = sort_preselect(purpose)
      end

      attr_reader :purpose, :selected_value

      # Helper method from the original partial
      def add_prompt(collection)
        [[I18n.t("basics.select"), ""]] + collection
      end

      # Helper method from the original partial
      def sort_preselect(purpose)
        return nil unless purpose == "clicker"

        Medium.select_generic.find { |x| x[1] == "Question" }[1]
      end
    end
  end
end

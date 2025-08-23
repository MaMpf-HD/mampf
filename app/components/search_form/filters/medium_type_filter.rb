# app/components/search_form/filters/medium_type_filter.rb
module SearchForm
  module Filters
    class MediumTypeFilter < Fields::MultiSelectField
      def initialize(current_user:, purpose: "media", **)
        super(
          name: :types,
          label: I18n.t("basics.types"), # Plural for media
          help_text: I18n.t("search.media.type"),
          collection: media_sorts_select(current_user, purpose),
          selected: sort_preselect(purpose),
          **
        )

        @purpose = purpose
        @current_user = current_user

        # Update options based on purpose
        @options[:multiple] = purpose.in?(["media", "import"])
        @options[:disabled] = purpose == "media"
      end

      attr_reader :purpose, :current_user

      # Skip the "all" checkbox when purpose is "import"
      def skip_all_checkbox?
        purpose.in?(["import", "quiz"])
      end

      def sort_preselect(purpose)
        return "" unless purpose == "quiz"

        "Question"
      end

      def media_sorts_select(current_user, purpose)
        return Medium.select_quizzables if purpose == "quiz"
        return Medium.select_importables if purpose == "import"
        return Medium.select_generic unless current_user.admin_or_editor?

        Medium.select_sorts
      end
    end
  end
end

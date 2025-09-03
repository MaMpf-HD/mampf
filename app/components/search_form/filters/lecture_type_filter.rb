module SearchForm
  module Filters
    # Renders a multi-select field for filtering by lecture type.
    # This component is a simple specialization of `MultiSelectField`, pre-configured
    # with a specific name, label, and a collection of lecture types sourced
    # from the `Lecture.select_sorts` method.
    class LectureTypeFilter < Fields::MultiSelectField
      # Initializes the LectureTypeFilter.
      #
      # This component is specialized and hard-codes its own options for the
      # underlying `MultiSelectField`. The collection of lecture types is
      # provided by the `Lecture.select_sorts` class method.
      #
      # @param ** [Hash] Catches any other keyword arguments, which are passed
      #   to the superclass (`MultiSelectField`).
      def initialize(**)
        super(
          name: :types,
          label: I18n.t("basics.type"),
          help_text: I18n.t("search.filters.helpdesks.lecture_type_filter"),
          collection: Lecture.select_sorts,
          **
        )
      end
    end
  end
end

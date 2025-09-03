module SearchForm
  module Filters
    # Renders a multi-select field for filtering by users who are teachers.
    # This component is a simple specialization of `MultiSelectField`, pre-configured
    # with a specific name, label, and a collection of teachers sourced
    # from the `User.select_teachers` method.
    class TeacherFilter < Fields::MultiSelectField
      # Initializes the TeacherFilter.
      #
      # This component is specialized and hard-codes its own options for the
      # underlying `MultiSelectField`. The collection of teachers is
      # provided by the `User.select_teachers` class method.
      #
      # @param ** [Hash] Catches any other keyword arguments, which are passed
      #   to the superclass (`MultiSelectField`).
      def initialize(**)
        super(
          name: :teacher_ids,
          label: I18n.t("basics.teachers"),
          help_text: I18n.t("search.filters.helpdesks.teacher_filter"),
          collection: User.select_teachers,
          **
        )
      end
    end
  end
end

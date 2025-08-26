module SearchForm
  module Filters
    # Renders a multi-select field for filtering by terms.
    # This component is a simple specialization of `MultiSelectField`, pre-configured
    # with a specific name, label, and a collection of terms sourced
    # from the `Term.select_terms` method.
    class TermFilter < Fields::MultiSelectField
      # Initializes the TermFilter.
      #
      # This component is specialized and hard-codes its own options for the
      # underlying `MultiSelectField`. The collection of terms is
      # provided by the `Term.select_terms` class method.
      #
      # @param ** [Hash] Catches any other keyword arguments, which are passed
      #   to the superclass (`MultiSelectField`).
      def initialize(**)
        super(
          name: :term_ids,
          label: I18n.t("basics.term"),
          help_text: I18n.t("admin.lecture.info.search_term"),
          collection: Term.select_terms,
          **
        )
      end
    end
  end
end

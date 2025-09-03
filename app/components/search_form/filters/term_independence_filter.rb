module SearchForm
  module Filters
    # Renders a checkbox for filtering by term independence.
    # This component is a simple specialization of `CheckboxField`, pre-configured
    # with a specific name, label, and a default unchecked state.
    class TermIndependenceFilter < Fields::CheckboxField
      # Initializes the TermIndependenceFilter.
      #
      # This component is specialized and hard-codes its own options for the
      # underlying `CheckboxField`.
      #
      # @param ** [Hash] Catches any other keyword arguments, which are passed
      #   to the superclass (`CheckboxField`). This can be used to pass options
      #   like `:container_class`.
      def initialize(**)
        super(
          name: :term_independent,
          label: I18n.t("admin.course.term_independent"),
          help_text: I18n.t("search.filters.helpdesks.term_independence_filter"),
          checked: false,
          **
        )
      end
    end
  end
end

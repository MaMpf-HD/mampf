# frozen_string_literal: true

module SearchForm
  module Filters
    # Term filter for selecting academic terms
    #
    # This filter provides a multi-select dropdown for choosing academic terms
    # (semesters). It uses the Term model's select_terms method which provides
    # an optimized collection of terms formatted for dropdown display.
    #
    # Features:
    # - Multi-select term dropdown
    # - Uses Term.select_terms for optimized query
    # - Internationalized labels and help text
    # - Commonly used for filtering lectures, courses, and other academic content
    #
    # @example Basic term filter
    #   add_term_filter
    #
    # The collection is generated using Term.select_terms which provides
    # terms in a format suitable for form select options.
    class TermFilter < Fields::MultiSelectField
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

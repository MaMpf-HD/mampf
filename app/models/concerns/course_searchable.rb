module CourseSearchable
  extend ActiveSupport::Concern

  # Class Methods to be added to the including model Course
  class_methods do
    # Define the filter chain for this model.
    def search_filters
      [
        :apply_editor_filter,
        :apply_program_filter,
        :apply_term_independence_filter,
        :apply_fulltext_filter
      ]
    end

    # Define the default sort order for this model.
    def default_search_order
      Arel.sql("LOWER(unaccent(title))")
    end

    private

      # Define any one-off filters that are specific to this model.
      def apply_term_independence_filter(scope, params)
        return scope unless params[:term_independent] == "1"

        scope.term_independent_only
      end
  end

  # Setup to be run when the concern is included
  included do
    # Include all the granular filter implementations
    include FilterableByEditor
    include FilterableByProgram
    include FilterableByFulltext

    # Define the pg_search scope for this model
    pg_search_scope :search_by_title,
                    against: :title,
                    using: {
                      tsearch: { prefix: true, any_word: true },
                      trigram: { word_similarity: true,
                                 threshold: 0.3 }
                    }

    scope :term_independent_only, -> { where(term_independent: true) }
  end
end

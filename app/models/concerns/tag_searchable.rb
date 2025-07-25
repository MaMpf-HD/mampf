module TagSearchable
  extend ActiveSupport::Concern

  # Class Methods to be added to the including model Tag
  class_methods do
    def search_filters
      [:apply_course_filter, :apply_fulltext_filter]
    end

    def default_search_order
      # Returning nil will prevent any default ordering from being applied.
      # The results will be ordered by relevance if full-text search is used,
      # or by the database's default order otherwise.
      nil
    end

    private

      # Filter by title using the pg_search scope.
      def apply_fulltext_filter(scope, params)
        return scope if params[:title].blank?

        # Use with_pg_search_rank to make ordering by relevance compatible
        # with the .distinct scope from the course filter.
        scope.search_by_title(params[:title]).with_pg_search_rank
      end
  end

  included do
    # Include all the granular filter implementations
    include FilterableByCourse
    include FilterableByFulltext

    self.fulltext_parameter = :title

    # Define the pg_search scope.
    # It searches against the `title` in the associated `notions` table.
    pg_search_scope :search_by_title,
                    associated_against: {
                      notions: :title,
                      aliases: :title
                    },
                    using: {
                      tsearch: { prefix: true, any_word: true },
                      trigram: { word_similarity: true,
                                 threshold: 0.3 }
                    }
  end
end

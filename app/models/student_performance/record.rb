module StudentPerformance
  # One student's standing in one lecture, worked out from their marked
  # assignments and achievements and written down here. Everything with a
  # `_materialized` suffix is derived and rewritten by `ComputationService`;
  # nothing else may set it, and it is never the place to correct a mistake.
  class Record < ApplicationRecord
    belongs_to :lecture
    belongs_to :user

    validates :lecture_id, uniqueness: { scope: :user_id }

    # Counts among the given tests only: the stored lists may still hold a
    # test that has lost its threshold or been deleted.
    def tests_passed_among(test_ids)
      among(tests_passed_ids, test_ids)
    end

    def tests_failed_among(test_ids)
      among(tests_failed_ids, test_ids)
    end

    private

      def among(recorded_ids, test_ids)
        (Array(recorded_ids).to_set(&:to_i) & test_ids.to_set).size
      end
  end
end

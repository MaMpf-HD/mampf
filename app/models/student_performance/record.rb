module StudentPerformance
  # One student's standing in one lecture, worked out from their marked
  # assignments and achievements and written down here. Everything with a
  # `_materialized` suffix is derived and rewritten by `ComputationService`;
  # nothing else may set it, and it is never the place to correct a mistake.
  class Record < ApplicationRecord
    belongs_to :lecture
    belongs_to :user

    validates :lecture_id, uniqueness: { scope: :user_id }
  end
end

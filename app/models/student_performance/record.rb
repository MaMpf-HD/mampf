module StudentPerformance
  class Record < ApplicationRecord
    STALE_THRESHOLD = 7.days

    belongs_to :lecture
    belongs_to :user

    validates :lecture_id, uniqueness: { scope: :user_id }

    def stale?
      computed_at.present? && computed_at < STALE_THRESHOLD.ago
    end
  end
end

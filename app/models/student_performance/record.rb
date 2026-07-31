module StudentPerformance
  class Record < ApplicationRecord
    belongs_to :lecture
    belongs_to :user

    validates :lecture_id, uniqueness: { scope: :user_id }
  end
end

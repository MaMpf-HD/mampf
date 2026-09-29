module Dashboard
  # A student's chosen tape color for one lecture's dashboard card. Falls back
  # to Dashboard::WashiTape's seeded color when no row exists.
  class CardStyle < ApplicationRecord
    belongs_to :user
    belongs_to :lecture

    # Stored as integers, so each color keeps its number however
    # WashiTape::COLORS is reordered.
    enum :tape_color, { butter: 0, rose: 1, mint: 2, sky: 3, lavender: 4, peach: 5 },
         prefix: :tape, validate: true

    validates :lecture_id, uniqueness: { scope: :user_id }
  end
end

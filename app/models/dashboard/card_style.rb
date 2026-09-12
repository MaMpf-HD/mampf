module Dashboard
  # A student's chosen tape color for one lecture's dashboard card. Falls back
  # to Dashboard::WashiTape's seeded color when no row exists.
  class CardStyle < ApplicationRecord
    belongs_to :user
    belongs_to :lecture

    enum :tape_color, WashiTape::COLORS.each_with_index.to_h, prefix: :tape

    validates :lecture_id, uniqueness: { scope: :user_id }
  end
end

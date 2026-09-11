module Dashboard
  # How one student wants one lecture's card to look on their dashboard.
  #
  # Kept apart from why the card is there in the first place — a roster
  # membership or a bookmark — so that recoloring a card never changes what
  # the dashboard is telling the student about that lecture. A lecture with no
  # row here falls back to the seeded color Dashboard::WashiTape picks.
  class CardStyle < ApplicationRecord
    belongs_to :user
    belongs_to :lecture

    enum :tape_color, WashiTape::COLORS.each_with_index.to_h, prefix: :tape

    validates :lecture_id, uniqueness: { scope: :user_id }
  end
end

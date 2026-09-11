class WatchlistEntry < ApplicationRecord
  default_scope { order :medium_position }
  belongs_to :watchlist
  belongs_to :medium

  acts_as_list scope: :watchlist, top_of_list: 0, column: :medium_position

  validates :medium_id, uniqueness: { scope: :watchlist_id }
  validate :medium_is_proper

  private

    # A random quiz is what a self test leaves behind: it belongs to no lecture,
    # has no page of its own, and Medium.expired throws it away a day later.
    # Nothing may collect it.
    def medium_is_proper
      return if medium.nil? || medium.proper?

      errors.add(:medium, :improper)
    end
end

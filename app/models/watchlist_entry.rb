class WatchlistEntry < ApplicationRecord
  default_scope { order :medium_position }
  belongs_to :watchlist
  belongs_to :medium
  acts_as_list scope: :watchlist, top_of_list: 0, column: :medium_position

  validates :medium_id, uniqueness: { scope: :watchlist_id }
end

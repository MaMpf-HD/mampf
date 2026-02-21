class WatchlistEntry < ApplicationRecord
  default_scope { order :medium_position }
  belongs_to :watchlist, optional: false
  belongs_to :medium, optional: false

  acts_as_list scope: :watchlist, top_of_list: 0, column: :medium_position

  validates :medium_id, uniqueness: { scope: :watchlist_id }
end

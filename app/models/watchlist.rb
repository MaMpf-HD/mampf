class Watchlist < ApplicationRecord
  belongs_to :user
  has_many :watchlist_entries, dependent: :destroy
  has_many :media, through: :watchlist_entries

  validates :name, presence: true, uniqueness: { scope: :user_id }

  def owned_by?(other_user)
    user == other_user
  end
end

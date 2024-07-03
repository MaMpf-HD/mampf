class Watchlist < ApplicationRecord
  belongs_to :user
  has_many :watchlist_entries, dependent: :destroy
  has_many :media, through: :watchlist_entries

  # rubocop:todo Rails/UniqueValidationWithoutIndex
  validates :name, presence: true, uniqueness: { scope: :user_id }
  # rubocop:enable Rails/UniqueValidationWithoutIndex

  def owned_by?(other_user)
    user == other_user
  end
end

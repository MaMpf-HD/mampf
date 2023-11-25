class Watchlist < ApplicationRecord
  belongs_to :user
  has_many :watchlist_entries, dependent: :destroy
  has_many :media, through: :watchlist_entries

  # rubocop:todo Rails/UniqueValidationWithoutIndex
  validates :name, presence: true, uniqueness: { scope: :user_id }
  # rubocop:enable Rails/UniqueValidationWithoutIndex

  # rubocop:todo Naming/VariableName
  def owned_by?(otherUser) # rubocop:todo Naming/MethodParameterName, Naming/VariableName
    # rubocop:enable Naming/VariableName
    user == otherUser # rubocop:todo Naming/VariableName
  end
end

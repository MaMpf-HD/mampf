class Streak < ApplicationRecord
  belongs_to :user
  belongs_to :streakable, polymorphic: true

  validates :value, numericality: { greater_than_or_equal_to: 0 }
  validates :last_activity, inclusion: { in: (..5.minutes.from_now) }
end

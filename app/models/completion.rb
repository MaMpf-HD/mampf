class Completion < ApplicationRecord
  belongs_to :user
  belongs_to :lecture
  belongs_to :completable, polymorphic: true

  validates :user_id, uniqueness: { scope: [:completable_type, :completable_id] }
end

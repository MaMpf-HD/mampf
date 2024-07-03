class Import < ApplicationRecord
  belongs_to :medium
  belongs_to :teachable, polymorphic: true

  # rubocop:todo Rails/UniqueValidationWithoutIndex
  validates :medium, uniqueness: { scope: [:teachable] }
  # rubocop:enable Rails/UniqueValidationWithoutIndex
end

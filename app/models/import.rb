class Import < ApplicationRecord
  belongs_to :medium
  belongs_to :teachable, polymorphic: true

  validates :medium, uniqueness: { scope: [:teachable] }
end

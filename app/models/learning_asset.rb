class LearningAsset < ApplicationRecord
  belongs_to :teachable, polymorphic: true
  has_many :asset_media
  has_many :media, through: :asset_media
  has_many :asset_tags
  has_many :tags, through: :asset_tags
  validates :title, presence: true, uniqueness: true
end

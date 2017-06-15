class LearningAsset < ApplicationRecord
  belongs_to :course, optional: true
  belongs_to :lecture, optional: true
  belongs_to :lesson, optional: true
  has_many :asset_media
  has_many :media, through: :asset_media
  has_many :asset_tags
  has_many :tags, through: :asset_tags
end

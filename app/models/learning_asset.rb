class LearningAsset < ApplicationRecord
  has_many :learning_media
  has_many :media, through: :learning_media
end

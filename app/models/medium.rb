class Medium < ApplicationRecord
  actable
  has_many :learning_media
  has_many :learning_assets, through: :learning_media
end

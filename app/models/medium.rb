class Medium < ApplicationRecord
  has_many :asset_media
  has_many :learning_assets, through: :asset_media
end

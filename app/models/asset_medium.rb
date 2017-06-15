class AssetMedium < ApplicationRecord
  belongs_to :learning_asset
  belongs_to :medium
end

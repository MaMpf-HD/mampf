class AssetTag < ApplicationRecord
  belongs_to :learning_asset
  belongs_to :tag
end

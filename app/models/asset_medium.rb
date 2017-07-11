# AssetMedium class
# JoinTable for learning_asset <-> medium many-to-many-relation
class AssetMedium < ApplicationRecord
  belongs_to :learning_asset
  belongs_to :medium
end

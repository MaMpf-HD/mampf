# AssetTag class
# JoinTable for learning_asset <-> tag many-to-many-relation
class AssetTag < ApplicationRecord
  belongs_to :learning_asset
  belongs_to :tag
end

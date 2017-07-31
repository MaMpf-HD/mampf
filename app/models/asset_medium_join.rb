# AssetMedium class
# JoinTable for asset <-> medium many-to-many-relation
class AssetMediumJoin < ApplicationRecord
  belongs_to :asset
  belongs_to :medium
end

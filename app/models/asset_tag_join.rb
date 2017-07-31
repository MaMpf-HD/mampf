# AssetTagJoin class
# JoinTable for asset <-> tag many-to-many-relation
class AssetTagJoin < ApplicationRecord
  belongs_to :asset
  belongs_to :tag
end

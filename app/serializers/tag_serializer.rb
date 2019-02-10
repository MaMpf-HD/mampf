# TagSerializer class for API
class TagSerializer < ActiveModel::Serializer
  attributes :id, :title
  has_many :related_tags
  has_many :media
end

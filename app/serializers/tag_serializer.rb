class TagSerializer < ActiveModel::Serializer
  attributes :id, :title
  has_many :related_tags
end

class MediumSerializer < ActiveModel::Serializer
  attribute :video_url
  attribute :video_width, key: :width
  attribute :video_height, key: :height
end

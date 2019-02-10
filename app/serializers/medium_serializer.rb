# MediumSerializer class for API
class MediumSerializer < ActiveModel::Serializer
  attribute :video_url, key: :video_file_link
  attribute :video_width, key: :width
  attribute :video_height, key: :height
end

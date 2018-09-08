class MediumSerializer < ActiveModel::Serializer
  attribute :video_file_link
  attribute :video_width, key: :width
  attribute :video_height, key: :height
end

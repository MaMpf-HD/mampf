class MediumSerializer < ActiveModel::Serializer
  attributes :id, :video_stream_link, :video_file_link, :video_thumbnail_link,
             :manuscript_link, :external_reference_link, :width, :height,
             :embedded_width, :embedded_height, :length, :pages,
             :manuscript_size, :title, :author, :video_size,
             :authoring_software, :sort, :question_id, :description
  has_many :assets
end

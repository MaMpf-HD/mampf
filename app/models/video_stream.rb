class VideoStream < ApplicationRecord
  has_many :hyperlinks, as: :linkable
  has_many :learning_video_streams
  has_many :learning_assets, through: :learning_video_streams
end

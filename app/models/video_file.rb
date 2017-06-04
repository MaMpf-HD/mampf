class VideoFile < ApplicationRecord
  has_one :hyperlink, as: :linkable
  has_many :learning_video_files
  has_many :learning_assets, through: :learning_video_files
end

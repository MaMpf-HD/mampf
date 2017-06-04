class LearningAsset < ApplicationRecord
  has_many :learning_video_files
  has_many :video_files, through: :learning_video_files
  has_many :learning_video_streams
  has_many :video_streams, through: :learning_video_streams
  has_many :learning_manuscripts
  has_many :manuscripts, through: :learning_manuscripts
  has_many :learning_references
  has_many :external_references, through: :learning_references
end

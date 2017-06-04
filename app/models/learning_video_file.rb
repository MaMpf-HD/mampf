class LearningVideoFile < ApplicationRecord
  belongs_to :learning_asset
  belongs_to :video_file
end

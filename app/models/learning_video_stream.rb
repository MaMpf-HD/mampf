class LearningVideoStream < ApplicationRecord
  belongs_to :learning_asset
  belongs_to :video_stream
end

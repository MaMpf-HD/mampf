class LearningMedium < ApplicationRecord
  belongs_to :medium
  belongs_to :learning_asset
end

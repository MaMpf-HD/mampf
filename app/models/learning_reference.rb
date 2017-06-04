class LearningReference < ApplicationRecord
  belongs_to :learning_asset
  belongs_to :external_reference
end

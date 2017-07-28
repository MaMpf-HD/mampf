class Connection < ApplicationRecord
  belongs_to :learning_asset
  belongs_to :linked_asset, class_name: 'LearningAsset'
end

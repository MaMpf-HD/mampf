class ExternalReference < ApplicationRecord
  has_many :learning_references
  has_many :learning_assets, through: :learning_references
end

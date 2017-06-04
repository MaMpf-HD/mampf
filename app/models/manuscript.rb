class Manuscript < ApplicationRecord
  has_one :hyperlink, as: :linkable
  has_many :learning_manuscripts
  has_many :learning_assets, through: :learning_manuscripts
end

class Chapter < ApplicationRecord
  belongs_to :lecture
  has_many :sections
end

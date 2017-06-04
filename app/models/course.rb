class Course < ApplicationRecord
  has_many :lectures
  has_many :contents
  has_many :tags, through: :contents
end

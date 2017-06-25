class Course < ApplicationRecord
  has_many :lectures
  has_many :course_contents
  has_many :tags, through: :course_contents
  has_many :learning_assets
  validates :title, presence: true, uniqueness: true
end

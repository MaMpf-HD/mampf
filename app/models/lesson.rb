class Lesson < ApplicationRecord
  belongs_to :lecture
  has_many :lesson_contents
  has_many :tags, through: :lesson_contents
  has_many :learning_assets
end

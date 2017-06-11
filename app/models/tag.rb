class Tag < ApplicationRecord
  alias_attribute :disabled_lectures, :lectures
  has_many :course_contents
  has_many :courses, through: :course_contents
  has_many :disabled_contents
  has_many :lectures, through: :disabled_contents
  has_many :lesson_contents
  has_many :lessons, through: :lesson_contents
end

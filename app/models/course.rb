# Course class
class Course < ApplicationRecord
  has_many :lectures
  has_many :course_contents
  has_many :tags, through: :course_contents
  has_many :learning_assets, as: :teachable
  validates :title, presence: true, uniqueness: true

  def learning_assets_in_lectures
    LearningAsset.where(teachable: lectures)
  end

  def learning_assets_in_lessons
    lessons = Lesson.where(lecture: lectures)
    LearningAsset.where(teachable: lessons)
  end
end

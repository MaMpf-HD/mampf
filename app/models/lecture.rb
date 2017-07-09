class Lecture < ApplicationRecord
  belongs_to :course
  belongs_to :teacher
  belongs_to :term
  has_many :disabled_contents
  has_many :disabled_tags, through: :disabled_contents, source: :tag
  has_many :lessons
  has_many :learning_assets, as: :teachable
  validates :course, uniqueness: { scope: [:teacher_id, :term_id],
                                   message: 'already exists' }

  def learning_assets_in_lessons
    LearningAsset.where(teachable: lessons)
  end
  def tags
    disabled_ids =  disabled_tags.map(&:id)
    course.tags.where.not(id: disabled_ids)
  end
end

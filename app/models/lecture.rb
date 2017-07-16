class Lecture < ApplicationRecord
  belongs_to :course
  belongs_to :teacher
  belongs_to :term
  has_many :disabled_contents
  has_many :disabled_tags, through: :disabled_contents, source: :tag
  has_many :additional_contents
  has_many :additional_tags, through: :additional_contents, source: :tag
  has_many :lessons
  has_many :learning_assets, as: :teachable
  validates :course, uniqueness: { scope: [:teacher_id, :term_id],
                                   message: 'already exists' }

  def learning_assets_in_lessons
    LearningAsset.where(teachable: lessons)
  end

  def tags
    course_tag_ids = course.tags.pluck(:id)
    disabled_ids = disabled_tags.pluck(:id)
    additional_ids = additional_tags.pluck(:id)
    tag_ids = (course_tag_ids | additional_ids) - disabled_ids
    Tag.where(id: tag_ids)
  end
end

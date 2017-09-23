# Lecture class
class Lecture < ApplicationRecord
  belongs_to :course
  belongs_to :teacher
  belongs_to :term
  has_many :lecture_tag_disabled_joins
  has_many :disabled_tags, through: :lecture_tag_disabled_joins, source: :tag
  has_many :lecture_tag_additional_joins
  has_many :additional_tags, through: :lecture_tag_additional_joins,
                             source: :tag
  has_many :chapters
  has_many :lessons
  has_many :assets, as: :teachable
  has_many :media, as: :teachable
  has_many :lecture_user_joins
  has_many :users, through: :lecture_user_joins
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

  def sections
    Section.where(chapter: chapters)
  end

  def to_label
    course.title + ' | ' + term.season + ' ' + term.year.to_s + ' '
  end

  def description
    { general: to_label, specific: '' }
  end

end

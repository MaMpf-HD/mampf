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
  has_many :chapters, dependent: :destroy
  has_many :lessons, dependent: :destroy
  has_many :media, as: :teachable
  has_many :lecture_user_joins, dependent: :destroy
  has_many :users, through: :lecture_user_joins
  has_many :connections, dependent: :destroy
  has_many :preceding_lectures, through: :connections
  validates :kaviar, inclusion: { in: [true, false] }
  validates :reste, inclusion: { in:  [true, false] }
  validates :sesam, inclusion: { in: [true, false] }
  validates :erdbeere, inclusion: { in: [true, false] }
  validates :kiwi, inclusion: { in: [true, false] }
  validates :keks, inclusion: { in: [true, false] }
  validates :course, uniqueness: { scope: [:teacher_id, :term_id],
                                   message: 'already exists' }

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

  def kaviar?
    Rails.cache.fetch("#{cache_key}/kaviar", expires_in: 2.hours) do
      Medium.where(sort: 'Kaviar').any? { |m| m.lecture == self }
    end
  end

  def sesam?
    Rails.cache.fetch("#{cache_key}/sesam", expires_in: 2.hours) do
      Medium.where(sort: 'Sesam').any? { |m| m.lecture == self }
    end
  end

  def keks?
    Rails.cache.fetch("#{cache_key}/keks", expires_in: 2.hours) do
      Medium.where(sort: ['KeksQuiz', 'KeksQuestion']).any? { |m| m.lecture == self }
    end
  end

  def erdbeere?
    Rails.cache.fetch("#{cache_key}/erdbeere", expires_in: 2.hours) do
      Medium.where(sort: 'Erdbeere').any? { |m| m.lecture == self }
    end
  end

  def kiwi?
    Rails.cache.fetch("#{cache_key}/kiwi", expires_in: 2.hours) do
      Medium.where(sort: 'Kiwi').any? { |m| m.lecture == self }
    end
  end

  def reste?
    Rails.cache.fetch("#{cache_key}/reste", expires_in: 2.hours) do
      Medium.where(sort: 'Reste').any? { |m| m.lecture == self }
    end
  end

  def available_modules
    [nil, kaviar?, sesam?, kiwi?, keks?, reste?]
  end

  def to_label
    course.title + ', ' + term.to_label
  end

  def short_title
    course.short_title + ' ' + term.to_label_short
  end

  def title
    return 'Vorlesung #' + id.to_s unless course.present? && term.present?
    course.title + ', ' + term.to_label
  end

  def term_teacher_info
    term.to_label + ', ' + teacher.name
  end

  def modules
    { 'KaViaR' => kaviar?, 'SeSAM' => sesam?, 'RestE' => reste?, 'KeKs' => keks?,
      'ErDBeere' => erdbeere?, 'KIWi' => kiwi? }
  end

  def description
    { general: to_label }
  end

  def newest?
    self == course.lectures_by_date.first
  end

  def newest_kaviar?
    self == course.kaviar_lectures_by_date.first
  end

  def lesson
  end

  def lecture
    self
  end
end

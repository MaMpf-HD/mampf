# Section class
class Section < ApplicationRecord
  belongs_to :chapter
  has_many :section_tag_joins
  has_many :tags, through: :section_tag_joins
  has_many :lesson_section_joins
  has_many :lessons, through: :lesson_section_joins
  validates :title, presence: true
  validates :number, presence: true,
                     numericality: { only_integer: true,
                                     greater_than_or_equal_to: 0,
                                     less_than_or_equal_to: 999 },
                     uniqueness: { scope: :chapter_id,
                                   message: 'section already exists' }
  validate :valid_lessons?
  validate :valid_tags?

  def lecture
    return unless chapter.present?
    chapter.lecture
  end

  def to_label
    return '§' + number.to_s + '. ' + title unless number_alt.present?
    '§' + number_alt + '. ' + title
  end

  private

  def valid_lessons?
    return unless chapter.present? && lessons.present?
    return true if lessons.pluck(:lecture_id).uniq == [lecture.id]
    errors.add(:date, 'lessons do not belong to lecture for chapter')
    false
  end

  def valid_tags?
    return unless chapter.present? && tags.present?
    return true if (tags.pluck(:id) - lecture.tags.pluck(:id)).empty?
    errors.add(:date, 'tags do not belong to lecture for chapter')
    false
  end
end

# Lesson class
class Lesson < ApplicationRecord
  belongs_to :lecture
  has_many :lesson_contents
  has_many :tags, through: :lesson_contents
  has_many :lesson_headings
  has_many :sections, through: :lesson_headings
  has_many :learning_assets, as: :teachable
  validates :date, presence: true
  validates :number, presence: true,
                     numericality: { only_integer: true,
                                     greater_than_or_equal_to: 1,
                                     less_than_or_equal_to: 999 },
                     uniqueness: { scope: :lecture_id,
                                   message: 'lesson already exists' }
  validate :valid_date?
  validate :valid_date_for_term?

  def term
    return unless lecture.present?
    lecture.term
  end

  def course
    return unless lecture.present?
    lecture.course
  end

  private

  def valid_date_for_term?
    return unless date.present? && term.present?
    return unless valid_date?
    return true if date.between?(term.begin_date, term.end_date)
    errors.add(:date, 'not a valid date for this term')
    false
  end

  def valid_date?
    return unless date.present?
    return if date.is_a?(Date)
    errors.add(:date, 'not a valid date')
    false
  end
end

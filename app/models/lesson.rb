# Lesson class
class Lesson < ApplicationRecord
  belongs_to :lecture
  has_many :lesson_tag_joins, dependent: :destroy
  has_many :tags, through: :lesson_tag_joins
  has_many :lesson_section_joins, dependent: :destroy
  has_many :sections, through: :lesson_section_joins
  has_many :media, as: :teachable
  has_many :editable_user_joins, as: :editable, dependent: :destroy
  validates :date, presence: { message: 'Es muss ein Datum angegeben werden.' }
  validates :sections, presence: { message: 'Es muss mindestens ein Abschnitt '\
                                            'angegeben werden.' }

  def self.select_by_date
    Lesson.all.to_a.sort_by(&:date).map { |l| [l.date, l.id] }
  end

  def term
    return unless lecture.present?
    lecture.term
  end

  def number
    lecture.lessons.order(:date, :id).pluck(:id).index(id) + 1
  end

  def course
    return unless lecture.present?
    lecture.course
  end

  def date_de
    date.day.to_s + '.' + date.month.to_s + '.' + date.year.to_s
  end

  def to_label
    'Nr. ' + number.to_s + ', ' + date_de.to_s
  end

  def title
    return 'Sitzung #' + id.to_s unless number.present? && date.present?
    'Sitzung ' + number.to_s + ', ' + date_de.to_s
  end

  def short_title_with_lecture
    lecture.short_title + ', S.' + number.to_s
  end

  def short_title_with_lecture_date
    lecture.short_title + ', ' + date_de
  end

  def section_titles
    sections.map(&:title).join(', ')
  end

  def description
    { general: lecture.to_label, specific: title }
  end

  def lesson
    self
  end

  def section_tags
    sections.collect(&:tags).flatten
  end

  def complement_of_section_tags
    Tag.all - section_tags
  end
end

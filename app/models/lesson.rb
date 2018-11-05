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
  after_save :touch_media
  before_destroy :touch_media

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
    'Sitzung ' + number.to_s + ', ' + date_de.to_s
  end

  def long_title
    lecture.title + ', ' + title
  end

  def short_title_with_lecture
    lecture.short_title + ', S.' + number.to_s
  end

  def short_title_with_lecture_date
    lecture.short_title + ', ' + date_de
  end

  def short_title
    lecture.short_title + '_E' + number.to_s
  end

  def title_for_viewers
    lecture.title_for_viewers + ', Sitzung ' + number.to_s + ' vom ' +
      date_de
  end

  def local_title_for_viewers
    'Sitzung ' + number.to_s + ' vom ' + date_de
  end

  def compact_title
    lecture.compact_title + '.E' + number.to_s
  end

  def section_titles
    sections.map(&:title).join(', ')
  end

  def card_header
    lecture.short_title_brackets + ', ' + date_de
  end

  def card_header_path(user)
    return unless user.lectures.include?(lecture)
    lesson_path
  end

  def lesson
    self
  end

  def media_scope
    lecture
  end

  def edited_by?(user)
    lecture.edited_by?(user)
  end

  def section_tags
    sections.collect(&:tags).flatten
  end

  def complement_of_section_tags
    Tag.all - section_tags
  end

  def section_selection
    sections.map { |s| [s.to_label, s.id]}
  end

  private

  def lesson_path
    Rails.application.routes.url_helpers.lesson_path(self)
  end

  def touch_media
    lecture.media_with_inheritance.each(&:touch)
  end
end

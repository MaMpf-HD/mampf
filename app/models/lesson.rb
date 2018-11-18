# Lesson class
class Lesson < ApplicationRecord
  belongs_to :lecture

  # a lesson has many tags
  has_many :lesson_tag_joins, dependent: :destroy
  has_many :tags, through: :lesson_tag_joins

  # a lesson has many sections
  # they correspon to these sections of the lecture's chapters who have been
  # taught in the lesson
  has_many :lesson_section_joins, dependent: :destroy
  has_many :sections, through: :lesson_section_joins

  # being a teachable (course/lecture/lesson), a lesson has associated media
  has_many :media, as: :teachable

  validates :date, presence: { message: 'Es muss ein Datum angegeben werden.' }
  validates :sections, presence: { message: 'Es muss mindestens ein Abschnitt '\
                                            'angegeben werden.' }

  # media are cached in several places
  # lessons are touched in order to find out whether cache is out of date
  after_save :touch_media
  before_destroy :touch_media

  # The next methods coexist for lectures and lessons as well.
  # Therefore, they can be called on any *teachable*

  def course
    return unless lecture.present?
    lecture.course
  end

  def lesson
    self
  end

  # a lesson should also see other lessons in the same lecture
  def media_scope
    lecture
  end

  def title
    'Sitzung ' + number.to_s + ', ' + date_de.to_s
  end

  def to_label
    'Nr. ' + number.to_s + ', ' + date_de.to_s
  end

  def compact_title
    lecture.compact_title + '.E' + number.to_s
  end

  def title_for_viewers
    lecture.title_for_viewers + ', Sitzung ' + number.to_s + ' vom ' +
      date_de
  end

  def long_title
    lecture.title + ', ' + title
  end

  def card_header
    lecture.short_title_brackets + ', ' + date_de
  end

  def card_header_path(user)
    return unless user.lectures.include?(lecture)
    lesson_path
  end

  # some more methods dealing with the title

  def short_title_with_lecture
    lecture.short_title + ', S.' + number.to_s
  end

  def short_title_with_lecture_date
    lecture.short_title + ', ' + date_de
  end

  def short_title
    lecture.short_title + '_E' + number.to_s
  end

  def local_title_for_viewers
    'Sitzung ' + number.to_s + ' vom ' + date_de
  end

  # more infos that can be extracted

  def term
    return unless lecture.present?
    lecture.term
  end

  # the number of a lesson is calculated by its date relative to the other
  # lessons
  def number
    lecture.lessons.order(:date, :id).pluck(:id).index(id) + 1
  end

  def date_de
    date.day.to_s + '.' + date.month.to_s + '.' + date.year.to_s
  end

  def section_titles
    sections.map(&:title).join(', ')
  end

  # a lesson can be edited by any user who can edit its lecture
  def edited_by?(user)
    lecture.edited_by?(user)
  end

  def section_tags
    sections.collect(&:tags).flatten
  end

  def complement_of_section_tags
    Tag.all - section_tags
  end

  # Returns the list of sections of this lesson (by label), together with
  # their ids.
  # Is used in options_for_select in form helpers.
  def section_selection
    sections.map { |s| [s.to_label, s.id] }
  end

  private

  # path for show lesson action
  def lesson_path
    Rails.application.routes.url_helpers.lesson_path(self)
  end

  # used for after save callback
  def touch_media
    lecture.media_with_inheritance.each(&:touch)
  end
end

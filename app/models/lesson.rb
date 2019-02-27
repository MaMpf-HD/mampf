# Lesson class
class Lesson < ApplicationRecord
  belongs_to :lecture, touch: true

  # a lesson has many tags
  has_many :lesson_tag_joins, dependent: :destroy
  has_many :tags, through: :lesson_tag_joins

  # a lesson has many sections
  # they correspond to these sections of the lecture's chapters who have been
  # taught in the lesson
  has_many :lesson_section_joins, dependent: :destroy
  has_many :sections, through: :lesson_section_joins

  # being a teachable (course/lecture/lesson), a lesson has associated media
  has_many :media, as: :teachable

  validates :date, presence: { message: 'Es muss ein Datum angegeben werden.' }
  validates :sections, presence: { message: 'Es muss mindestens ein Abschnitt '\
                                            'angegeben werden.' }

  # media are cached in several places
  # media are touched in order to find out whether cache is out of date
  after_save :touch_media
  # same for sections
  after_save :touch_sections
  after_save :touch_self
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

  def selector_value
    'Lesson-' + id.to_s
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

  def published?
    lecture.published?
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

  def previous
    lecture.lessons.find { |l| l.number == number - 1 }
  end

  def next
    lecture.lessons.find { |l| l.number == number + 1 }
  end

  def published_media
    media.published
  end

  # visible media are published with inheritance and not locked
  def visible_media
    media.select(&:visible?)
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

  # a lesson's items are all proper items (no self items, no pdf destinatins)
  # that belong to media associated to the lesson
  def items
    media.map(&:proper_items_by_time).flatten
  end

  def visible_items
    media.select(&:visible?)
         .map(&:proper_items_by_time).flatten
  end

  def content_items
    return visible_items if lecture.content_mode == 'video'
    script_items
  end

  # script items are items in the manuscript between start end end destination
  # (relevant if lecture content mode is manuscript)
  def script_items
    return [] unless lecture.manuscript && start_destination && end_destination
    start_item = Item.where(medium: lecture.manuscript,
                            pdf_destination: start_destination)&.first
    end_item = Item.where(medium: lecture.manuscript,
                            pdf_destination: end_destination)&.first
    return [] unless start_item && end_item
    range = (start_item.position..end_item.position).to_a
    return [] unless range.present?
    Item.where(medium: lecture.manuscript, position: range).order(:position)
  end

  # Returns the list of sections of this lesson (by label), together with
  # their ids.
  # Is used in options_for_select in form helpers.
  def section_selection
    sections.map { |s| [s.to_label, s.id] }
  end

  def self.order_reverse
    Lesson.includes(:lecture).order(:date).reverse
  end

  # returns the array of lessons that can be edited by the given user,
  # together with a string made up of 'Lesson' and their id
  # Is used in options_for_select in form helpers.
  def self.editable_selection(user)
    if user.admin?
      return Lesson.includes(:lecture).order_reverse
                   .map do |l|
                     [l.short_title_with_lecture_date, 'Lesson-' + l.id.to_s]
                   end
    end
    Lesson.includes(:lecture).order_reverse
          .select { |l| l.edited_by?(user) }
          .map { |l| [l.short_title_with_lecture_date, 'Lesson-' + l.id.to_s] }
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

  def touch_sections
    sections.each(&:touch)
  end

  def touch_self
    touch
  end
end

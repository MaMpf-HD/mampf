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
  has_many :sections, through: :lesson_section_joins,
                      after_remove: :touch_section,
                      after_add: :touch_section

  # being a teachable (course/lecture/lesson), a lesson has associated media
  has_many :media, -> { order(position: :asc) }, # rubocop:todo Rails/HasManyOrHasOneDependent
           as: :teachable,
           inverse_of: :lesson

  validates :date, presence: true
  validates :sections, presence: true

  before_destroy :touch_media
  before_destroy :touch_siblings
  before_destroy :touch_sections, prepend: true
  # media are cached in several places
  # media are touched in order to find out whether cache is out of date
  after_save :touch_media
  # same for sections and lessons in the same lecture (their numbering changes)
  after_save :touch_sections
  after_save :touch_siblings
  after_save :touch_self
  after_save :touch_tags

  delegate :editors_with_inheritance, to: :lecture, allow_nil: true

  # The next methods coexist for lectures and lessons as well.
  # Therefore, they can be called on any *teachable*

  def course
    return if lecture.blank?

    lecture.course
  end

  def lesson
    self
  end

  def talk
  end

  # a lesson should also see other lessons in the same lecture
  def media_scope
    lecture
  end

  def selector_value
    "Lesson-#{id}"
  end

  def title
    "#{I18n.t("lesson")} #{number}, #{date_localized}"
  end

  def to_label
    "Nr. #{number}, #{date_localized}"
  end

  def compact_title
    "#{lecture.compact_title}.E#{number}"
  end

  def cache_key
    "#{super}-#{I18n.locale}"
  end

  def title_for_viewers
    Rails.cache.fetch("#{cache_key_with_version}/title_for_viewers") do
      # rubocop:todo Layout/LineLength
      "#{lecture.title_for_viewers}, #{I18n.t("lesson")} #{number} #{I18n.t("from")} #{date_localized}"
      # rubocop:enable Layout/LineLength
    end
  end

  def long_title
    "#{lecture.title}, #{title}"
  end

  delegate :locale_with_inheritance, to: :lecture

  def locale
    locale_with_inheritance
  end

  def card_header
    "#{lecture.short_title_brackets}, #{date_localized}"
  end

  def card_header_path(user)
    return unless user.lectures.include?(lecture)

    lesson_path
  end

  delegate :published?, to: :lecture

  # some more methods dealing with the title

  def short_title_with_lecture
    "#{lecture.short_title}, S.#{number}"
  end

  def short_title_with_lecture_date
    "#{lecture.short_title}, #{date_localized}"
  end

  def short_title
    "#{lecture.short_title}_E#{number}"
  end

  def local_title_for_viewers
    "#{I18n.t("lesson")} #{number} #{I18n.t("from")} #{date_localized}"
  end

  delegate :restricted?, to: :lecture

  # more infos that can be extracted

  def term
    return if lecture.blank?

    lecture.term
  end

  def previous
    return unless number > 1

    lecture.lessons[number - 2]
  end

  def next
    lecture.lessons[number]
  end

  def published_media
    media.published
  end

  # visible media are published with inheritance and unlocked
  def visible_media_for_user(user)
    media.select { |m| m.visible_for_user?(user) }
  end

  delegate :visible_for_user?, to: :lecture

  # the number of a lesson is calculated by its date relative to the other
  # lessons
  def number
    lecture.lessons.index(self) + 1
  end

  def date_localized
    I18n.l(date, format: :concise)
  end

  def section_titles
    sections.map(&:title).join(", ")
  end

  # a lesson can be edited by any user who can edit its lecture
  delegate :edited_by?, to: :lecture

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
         .map(&:proper_items_by_time).flatten.reject(&:hidden)
  end

  def content_items
    return visible_items if lecture.content_mode == "video"

    script_items
  end

  def content
    ([details] + media.potentially_visible.map(&:content)).compact - [""]
  end

  def singular_medium
    return false if media.count != 1

    media.first
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
    return [] if range.blank?

    hidden_chapters = Chapter.where(hidden: true)
    hidden_sections = Section.where(hidden: true)
                             .or(Section.where(chapter: hidden_chapters))
    Item.where(medium: lecture.manuscript,
               position: range,
               hidden: [false, nil])
        .where.not(section: hidden_sections)
        .unquarantined.order(:position)
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
      return Lesson.order_reverse
                   .map do |l|
                     [l.title_for_viewers, "Lesson-#{l.id}"]
                   end
    end
    Lesson.includes(:lecture).order_reverse
          .select { |l| l.edited_by?(user) }
          .map { |l| [l.title_for_viewers, "Lesson-#{l.id}"] }
  end

  def guess_start_destination
    return start_destination if start_destination
    return unless previous

    probable_start_destination
  end

  def guess_end_destination
    return end_destination if end_destination
    return unless previous

    probable_start_destination
  end

  def probable_start_destination
    end_item = Item.where(medium: lecture.manuscript,
                          pdf_destination: previous.end_destination)&.first
    return unless end_item

    position = end_item.position
    return unless position

    successor = lecture.script_items_by_position.where("position > ?", position)
                       .order(:position)&.first&.pdf_destination
    return successor if successor

    end_item.pdf_destination
  end

  def tags_without_section
    tags.includes(:sections).select { |t| (t.sections & sections).empty? }
  end

  private

    # path for show lesson action
    def lesson_path
      Rails.application.routes.url_helpers.lesson_path(self)
    end

    # used for after save callback
    def touch_media
      lecture.media_with_inheritance.update(updated_at: Time.current)
    end

    def touch_siblings
      lecture.lessons.update(updated_at: Time.current)
    end

    def touch_sections
      sections.update(updated_at: Time.current)
      sections.map(&:chapter)
      sections.map(&:chapter).each(&:touch)
      lecture.touch
    end

    def touch_self
      touch
    end

    def touch_tags
      tags.update(updated_at: Time.current)
    end

    def touch_section(section)
      section.touch
      section.chapter.touch
    end
end

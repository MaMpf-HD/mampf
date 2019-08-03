# Chapter class
class Chapter < ApplicationRecord
  belongs_to :lecture, touch: true
  # the chapters of a lecture form an ordered list
  acts_as_list scope: :lecture
  has_many :sections, -> { order(position: :asc) }, dependent: :destroy
  validates :title, presence: true
  after_save :touch_sections
  after_save :touch_chapters
  before_destroy :touch_sections
  before_destroy :touch_chapters

  def to_label
    unless hidden
      return I18n.t('chapter', number: displayed_number, title: title)
    end
    I18n.t('hidden_chapter', number: displayed_number, title: title)
  end

  # Returns the number of the chapter. Unless the user explicitly specified
  # a display number, this number is calculated
  def displayed_number
    return calculated_number unless display_number.present?
    display_number
  end

  def reference
    Rails.cache.fetch("#{cache_key_with_version}/reference") do
      displayed_number
    end
  end

  # Returns the chapter number based on the position in the chapters list.
  def calculated_number
    return position.to_s unless lecture.start_chapter.present?
    (lecture.start_chapter + position - 1).to_s
  end

  # Returns all tags that are associated to sections within this chapter.
  def tags
    Tag.where(id: sections.map { |s| s.tags.pluck(:id) }.flatten)
  end

  # Returns all lessons that are associated to sections within this chapter.
  def lessons
    Lesson.where(id: sections.map { |s| s.lessons.pluck(:id) }.flatten)
  end

  #  Returns the last section of the chapter, based on the position.
  def last_section_by_position
    sections.order(:position).last
  end

  # Returns the list of sections of this chapter (by label), together with
  # their ids.
  # Is used in options_for_select in form helpers.
  def select_sections
    sections.includes(:chapter).order(:position)
            .map { |s| [s.to_label, s.position] }
  end

  def cache_key
    super + '-' + I18n.locale.to_s
  end

  def touch_chapters
    lecture.chapters.update_all(updated_at: Time.now)
  end

  def touch_sections
    unless lecture.absolute_numbering
      sections.update_all(updated_at: Time.now)
      return
    end
    Section.where(chapter: lecture.chapters).update_all(updated_at: Time.now)
  end
end

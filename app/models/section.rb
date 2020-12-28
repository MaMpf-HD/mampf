# Section class
class Section < ApplicationRecord
  # a section belongs to a chapter (of a lecture)
  belongs_to :chapter, touch: true

  # sections are ordered within a chapter
  acts_as_list scope: :chapter

  # a section has many tags
  has_many :section_tag_joins, dependent: :destroy
  has_many :tags, through: :section_tag_joins
  # the tags have an ordering (an array with their ids)
  serialize :tags_order, Array

  # a section has many lessons
  has_many :lesson_section_joins, dependent: :destroy
  has_many :lessons, -> { order(date: :asc, id: :asc) },
                     through: :lesson_section_joins

  # a section needs to have a title
  validates :title, presence: true

  # a section has many items, do not execute callbacks when section is destroyed
  has_many :items, dependent: :nullify

  # after saving or updating, touch lecture/media/self to keep cache up to date
  after_save :touch_lecture
  after_save :touch_media
  after_save :touch_self

  # if absolute numbering is enabled for the lecture, all chapters
  # and sections need to be touched because of possibly changed references
  after_save :touch_toc
  before_destroy :touch_toc

  before_destroy :touch_lecture
  before_destroy :touch_media

  def lecture
    chapter&.lecture
  end

  def reference_number
    return calculated_number unless display_number.present?
    display_number
  end

  def displayed_number
    '§' + reference_number
  end

  def reference
    Rails.cache.fetch("#{cache_key_with_version}/reference") do
      reference_number
    end
  end

  # calculate the number of the section depending on whether the lecture has
  # absolute section numbering or relative numbering with respect to the
  # chapters
  def calculated_number
    return relative_position unless lecture.absolute_numbering
    return absolute_position.to_s unless lecture.start_section.present?
    (absolute_position + lecture.start_section - 1).to_s
  end

  def to_label
    return displayed_number + '. ' + title unless hidden_with_inheritance?
    '*' + displayed_number + '. ' + title
  end

  # section's media are media that are contained in one of the
  # lessons of the section
  def media
    lessons.map(&:media).flatten
  end

   # visible media are published with inheritance and unlocked
  def visible_media_for_user(user)
    media.select { |m| m.visible_for_user?(user) }
  end

  def visible_for_user?(user)
    return true if user.admin
    return true if lecture.edited_by?(user)
    return false unless lecture.published?
    return false unless lecture.visible_for_user?(user)
    true
  end

  def previous_preliminary
    return higher_item unless first?
    return if chapter.first?
    return unless previous_chapter
    potential_last = previous_chapter.sections.last
    return potential_last if potential_last.last?
    potential_last.lower_items.last
  end

  # returns the previous section, taking into account that this is may be
  # within the previous chapter, and that the actual previous section may be
  # hidden (and therefore does not count)
  def previous
    possible_previous = previous_preliminary
    until possible_previous.nil? || !possible_previous.hidden_with_inheritance?
      possible_previous = possible_previous.previous_preliminary
    end
    possible_previous
  end

  def next_preliminary
    return lower_item unless last?
    return if chapter.last?
    return unless next_chapter
    potential_first = next_chapter.sections.first
    return potential_first if potential_first.first?
    potential_first.higher_items.first
  end

  # returns the next section, taking into account that this is may be
  # within the next chapter, and that the actual next section may be
  # hidden (and therefore does not count)
  def next
    possible_next = next_preliminary
    until possible_next.nil? || !possible_next.hidden_with_inheritance?
      possible_next = possible_next.next_preliminary
    end
    possible_next
  end

  def items_by_time
    lessons.order(:date).map(&:items).flatten.select { |i| i.section == self }
  end

  # returns items as provided by Script
  # (relevant if content mode is set to manuscript):
  # - disregards hidden items and items in quarantine
  def script_items_by_position
    Item.where(medium: lecture.manuscript,
               section: self)
        .unquarantined
        .unhidden
        .order(:position)
  end

  def visible_items_by_time
    lessons.order(:date).map { |l| l.visible_items }.flatten
           .select { |i| i.section == self }
  end

  def visible_items
    return visible_items_by_time if lecture.content_mode == 'video'
    script_items_by_position
  end

  def hidden_with_inheritance?
    chapter.hidden || hidden
  end

  def cache_key
    super + '-' + I18n.locale.to_s
  end

  private

  def touch_lecture
    return unless lecture.present? && lecture.persisted?
    lecture.touch
  end

  def touch_media
    lecture.media_with_inheritance.update_all(updated_at: Time.current)
    touch
  end

  def touch_self
    touch
  end

  def touch_toc
    return unless lecture.absolute_numbering
    lecture.chapters.update_all(updated_at: Time.now)
    lecture.sections.update_all(updated_at: Time.now)
  end

  def relative_position
    chapter.displayed_number + '.' + position.to_s
  end

  def absolute_position
    chapter.higher_items.includes(:sections).map(&:sections).flatten.size +
      position
  end

  def next_chapter
    # actual next chapter may not have any sections
    chapter.lower_items.find { |c| c.sections.exists? }
  end

  def previous_chapter
    # actual previous chapter may not have any sections
    chapter.higher_items.find { |c| c.sections.exists? }
  end
end

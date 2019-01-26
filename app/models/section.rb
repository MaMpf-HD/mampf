# Section class
class Section < ApplicationRecord
  belongs_to :chapter, touch: true
  acts_as_list scope: :chapter
  has_many :section_tag_joins, dependent: :destroy
  has_many :tags, through: :section_tag_joins
  has_many :lesson_section_joins, dependent: :destroy
  has_many :lessons, through: :lesson_section_joins
  validates :title, presence: { message: 'Es muss ein Titel angegeben werden.' }
  has_many :items, dependent: :nullify
  after_save :touch_lecture
  after_save :touch_media
  after_save :touch_self
  before_destroy :touch_lecture
  before_destroy :touch_media

  def lecture
    return unless chapter.present?
    chapter.lecture
  end

  def reference_number
    return calculated_number unless display_number.present?
    display_number
  end

  def displayed_number
    return '§' + reference_number
  end

  def calculated_number
    unless lecture.absolute_numbering
      return chapter.displayed_number + '.' + position.to_s
    end
    absolute_position = chapter.higher_items.includes(:sections).map(&:sections).flatten
                               .count + position
    return absolute_position.to_s unless lecture.start_section.present?
    (absolute_position + lecture.start_section - 1).to_s
  end

  def to_label
    displayed_number + '. ' + title
  end

  def media
    lessons.map(&:media).flatten
  end

  # returns the previous section, taking into account that this is may be
  # within the previous chapter
  def previous
    return higher_item unless first?
    return if chapter.first?
    # actual previous chapter may not have any sections
    previous_chapter = chapter.higher_items.find { |c| c.sections.exists? }
    return unless previous_chapter.present?
    potential_last = previous_chapter.sections.last
    return potential_last if potential_last.last?
    potential_last.lower_items.last
  end

  # returns the next section, taking into account that this is may be
  # within the next chapter
  def next
    return lower_item unless last?
    return if chapter.last?
    # actual next chapter may not have any sections
    next_chapter = chapter.lower_items.find { |c| c.sections.exists? }
    return unless next_chapter.present?
    potential_first = next_chapter.sections.first
    return potential_first if potential_first.first?
    potential_first.higher_items.first
  end

  def items_by_time
    lessons.order(:date).map(&:items).flatten.select { |i| i.section == self }
  end

  private

  def touch_lecture
    return unless lecture.present? && lecture.persisted?
    lecture.touch
  end

  def touch_media
    lecture.media_with_inheritance.each(&:touch)
    self.touch
  end

  def touch_self
    touch
  end
end

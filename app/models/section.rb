# Section class
class Section < ApplicationRecord
  belongs_to :chapter
  acts_as_list scope: :chapter
  has_many :section_tag_joins, dependent: :destroy
  has_many :tags, through: :section_tag_joins
  has_many :lesson_section_joins, dependent: :destroy
  has_many :lessons, through: :lesson_section_joins
  validates :title, presence: { message: 'Es muss ein Titel angegeben werden.' }
  has_many :items
  after_save :touch_lecture
  after_save :touch_media
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

  private

  def touch_lecture
    return unless lecture.present? && lecture.persisted?
    lecture.touch
  end

  def touch_media
    lecture.media_with_inheritance.each(&:touch)
  end
end

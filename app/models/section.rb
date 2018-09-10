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

  def long_reference
    chapter.lecture.short_title + ', ' + to_label
  end

  def calculated_number
    unless lecture.absolute_numbering
      return chapter.displayed_number + '.' + position.to_s
    end
    absolute_position = chapter.higher_items.map(&:sections).flatten
                               .count + position
    return absolute_position.to_s unless lecture.start_section.present?
    (absolute_position + lecture.start_section - 1).to_s
  end

  def to_label
    displayed_number + '. ' + title
  end
end

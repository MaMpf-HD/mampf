# Section class
class Section < ApplicationRecord
  belongs_to :chapter
  acts_as_list scope: :chapter
  has_many :section_tag_joins
  has_many :tags, through: :section_tag_joins
  has_many :lesson_section_joins
  has_many :lessons, through: :lesson_section_joins
  validates :title, presence: { message: 'Es muss ein Titel angegeben werden.'}
  validate :valid_lessons?
  validate :valid_tags?

  def lecture
    return unless chapter.present?
    chapter.lecture
  end

  def displayed_number
    return '§' + calculated_number unless display_number.present?
    '§' + display_number
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

  private

  def valid_lessons?
    return unless chapter.present? && lessons.present?
    return true if lessons.map(&:lecture_id).uniq == [lecture.id]
    errors.add(:lessons, 'The lessons you selected do not belong to the lecture ' \
                         'that is associated to to this section.')
    false
  end

  def valid_tags?
    return unless chapter.present? && tags.present?
    return true if (tags.map(&:id) - lecture.tags.pluck(:id)).empty?
    errors.add(:tags, 'The tags you selected are not activated for the ' \
                      'lecture that is associated to to this section.')
    false
  end
end

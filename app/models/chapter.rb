# Chapter class
class Chapter < ApplicationRecord
  belongs_to :lecture, touch: true
  # the chapters of a lecture form an ordered list
  acts_as_list scope: :lecture
  has_many :sections, -> { order(position: :asc) }, dependent: :destroy
  validates :title, presence: { message: 'Es muss ein Titel angegeben werden.' }

  def to_label
    'Kapitel ' + displayed_number + '. ' + title
  end

  # Returns the number of the chapter. Unless the user explicitly specified
  # a display number, this number is calculated
  def displayed_number
    return calculated_number unless display_number.present?
    display_number
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
end

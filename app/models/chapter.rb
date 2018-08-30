# Chapter class
class Chapter < ApplicationRecord
  belongs_to :lecture
  acts_as_list scope: :lecture
  has_many :sections, -> { order(position: :asc)}
  validates :title, presence: { message: 'Es muss ein Titel angegeben werden.'}

  def to_label
    'Kapitel ' + displayed_number + '. ' + title
  end

  def displayed_number
    return calculated_number unless display_number.present?
    display_number
  end

  def calculated_number
    return position.to_s unless lecture.start_chapter.present?
    (lecture.start_chapter + position - 1).to_s
  end

  def tags
    Tag.where(id: sections.map { |s| s.tags.pluck(:id) }.flatten)
  end

  def lessons
    Lesson.where(id: sections.map { |s| s.lessons.pluck(:id) }.flatten)
  end
end

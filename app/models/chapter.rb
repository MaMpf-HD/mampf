# Chapter class
class Chapter < ApplicationRecord
  belongs_to :lecture
  acts_as_list scope: :lecture
  has_many :sections, -> { order(position: :asc)}
  validates :title, presence: true
  validates :number, presence: true,
                     numericality: { only_integer: true,
                                     greater_than_or_equal_to: 0,
                                     less_than_or_equal_to: 999 },
                     uniqueness: { scope: :lecture_id,
                                   message: 'chapter already exists' }

  def to_label
    'Kapitel ' + display_number + '. ' + title
  end

  def display_number
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

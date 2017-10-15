# Chapter class
class Chapter < ApplicationRecord
  belongs_to :lecture
  has_many :sections
  validates :title, presence: true
  validates :number, presence: true,
                     numericality: { only_integer: true,
                                     greater_than_or_equal_to: 0,
                                     less_than_or_equal_to: 999 },
                     uniqueness: { scope: :lecture_id,
                                   message: 'chapter already exists' }

  def to_label
    'Kapitel ' + number.to_s + '. ' + title
  end

  def tags
    Tag.where(id: sections.all.map { |s| s.tags.pluck(:id) }.flatten)
  end

  def lessons
    Lesson.where(id: sections.all.map { |s| s.lessons.pluck(:id) }.flatten)
  end
end

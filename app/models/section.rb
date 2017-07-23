class Section < ApplicationRecord
  belongs_to :chapter
  has_many :lesson_headings
  has_many :lessons, through: :lesson_headings

  def lecture
    return unless chapter.present?
    chapter.lecture
  end
end

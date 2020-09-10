class Assignment < ApplicationRecord
  belongs_to :lecture, touch: true
  belongs_to :medium, optional: true

  validates :title, uniqueness: { scope: [:lecture_id] }, presence: true
end

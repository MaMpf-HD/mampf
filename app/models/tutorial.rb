# Tutorial model
class Tutorial < ApplicationRecord
  belongs_to :tutor, class_name: 'User', foreign_key: 'tutor_id', optional: true
  belongs_to :lecture, touch: true

  validates :title, uniqueness: { scope: [:lecture_id] }, presence: true
end

# Tutorial model
class Tutorial < ApplicationRecord
  belongs_to :tutor, class_name: 'User', foreign_key: 'tutor_id', optional: true
  belongs_to :lecture, touch: true
  has_many :submissions

  validates :title, uniqueness: { scope: [:lecture_id] }, presence: true

  def title_with_tutor
  	return title unless tutor
  	"#{title}, #{tutor.name}"
  end
end

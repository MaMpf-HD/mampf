# Tutorial model
class Tutorial < ApplicationRecord
  belongs_to :lecture, touch: true

  has_many :tutor_tutorial_joins, dependent: :destroy
  has_many :tutors, through: :tutor_tutorial_joins

  has_many :submissions, dependent: :destroy

  before_destroy :check_destructibility, prepend: true

  validates :title, uniqueness: { scope: [:lecture_id] }, presence: true

  def title_with_tutors
  	return "#{title}, #{I18n.t('basics.tba')}" unless tutors.any?
  	"#{title}, #{tutor_names}"
  end

  def tutor_names
  	return unless tutors.any?
  	tutors.map(&:tutorial_name).join(', ')
  end

  def destructible?
		Submission.where(tutorial: self).proper.none?
  end

  private

  def check_destructibility
  	throw(:abort) unless destructible?
  	true
  end
end

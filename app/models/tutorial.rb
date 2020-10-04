# Tutorial model
class Tutorial < ApplicationRecord
  belongs_to :tutor, class_name: 'User', foreign_key: 'tutor_id', optional: true
  belongs_to :lecture, touch: true
  has_many :submissions, dependent: :destroy

  before_destroy :check_destructibility, prepend: true

  validates :title, uniqueness: { scope: [:lecture_id] }, presence: true

  def title_with_tutor
  	return "#{title}, #{I18n.t('basics.tba')}" unless tutor
  	"#{title}, #{tutor.name}"
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

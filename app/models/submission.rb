class Submission < ApplicationRecord
  belongs_to :tutorial
  belongs_to :assignment

  has_many :user_submission_joins
  has_many :users, through: :user_submission_joins

  validate :matching_lecture

  private

	def matching_lecture
		return true if tutorial.lecture == assignment.lecture
		errors.add(:tutorial, :lecture_not_matching)
	end
end

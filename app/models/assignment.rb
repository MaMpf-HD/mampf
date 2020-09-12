class Assignment < ApplicationRecord
  belongs_to :lecture, touch: true
  belongs_to :medium, optional: true
  has_many :submissions

  validates :title, uniqueness: { scope: [:lecture_id] }, presence: true

  def find_submission(user)
  	UserSubmissionJoin.where(submission: Submission.where(assignment: self),
  													 user: user)
  									 &.first&.submission
  end
end

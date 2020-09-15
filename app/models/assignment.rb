class Assignment < ApplicationRecord
  belongs_to :lecture, touch: true
  belongs_to :medium, optional: true
  has_many :submissions

  validates :title, uniqueness: { scope: [:lecture_id] }, presence: true
  validates :deadline, presence: true

  def find_submission(user)
  	UserSubmissionJoin.where(submission: Submission.where(assignment: self),
  													 user: user)
  									 &.first&.submission
  end

  def active?
    deadline > Time.now
  end
end

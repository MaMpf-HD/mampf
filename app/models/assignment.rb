class Assignment < ApplicationRecord
  belongs_to :lecture, touch: true
  belongs_to :medium, optional: true
  has_many :submissions

  validates :title, uniqueness: { scope: [:lecture_id] }, presence: true
  validates :deadline, presence: true

  scope :active, -> { where('deadline >= ?', Time.now) }

  scope :expired, -> { where('deadline < ?', Time.now) }

  def self.current_in_lecture(lecture)
    Assignment.where(lecture: lecture).active.order(:deadline)&.first
  end

  def submission(user)
  	UserSubmissionJoin.where(submission: Submission.where(assignment: self),
  													 user: user)
  									 &.first&.submission
  end

  def active?
    deadline > Time.now
  end

  def previous
    siblings = lecture.assignments.order(:deadline)
    position = siblings.find_index(self)
    return unless position.positive?
    siblings[position - 1]
  end

  def submission_partners(user)
    submission = submission(user)
    return unless submission
    submission.users - [user]
  end

  def tutorial(user)
    submission(user).tutorial
  end
end

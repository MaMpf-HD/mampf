class Assignment < ApplicationRecord
  belongs_to :lecture, touch: true
  belongs_to :medium, optional: true
  has_many :submissions, dependent: :destroy

  before_destroy :check_destructibility, prepend: true

  validates :title, uniqueness: { scope: [:lecture_id] }, presence: true
  validates :deadline, presence: true

  scope :active, -> { where('deadline >= ?', Time.now) }

  scope :expired, -> { where('deadline < ?', Time.now) }

  def self.current_in_lecture(lecture)
    Assignment.where(lecture: lecture).active.order(:deadline)&.first
  end

  def self.previous_in_lecture(lecture)
    Assignment.where(lecture: lecture).expired.order(:deadline)&.last
  end

  def submission(user)
  	UserSubmissionJoin.where(submission: Submission.where(assignment: self),
  													 user: user)
  									 &.first&.submission
  end

  def active?
    Time.now <= deadline
  end

  def semiactive?
    Time.now <= friendly_deadline
  end

  def expired?
  	!active?
  end

  def totally_expired?
    !semiactive?
  end

  def in_grace_period?
    semiactive? && !active?
  end

  def friendly_deadline
    return deadline unless lecture.submission_grace_period
    deadline + lecture.submission_grace_period.minutes
  end

  def current?
  	self == Assignment.current_in_lecture(lecture)
  end

  def previous?
  	self == Assignment.previous_in_lecture(lecture)
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
    submission(user)&.tutorial
  end

  def destructible?
  	submissions.proper.none?
  end

  def check_destructibility
  	throw(:abort) unless destructible?
  	true
  end
end

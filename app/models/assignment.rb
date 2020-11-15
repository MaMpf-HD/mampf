class Assignment < ApplicationRecord
  belongs_to :lecture, touch: true
  belongs_to :medium, optional: true
  has_many :submissions, dependent: :destroy

  before_destroy :check_destructibility, prepend: true

  validates :title, uniqueness: { scope: [:lecture_id] }, presence: true
  validates :deadline, presence: true

  scope :active, -> { where('deadline >= ?', Time.now) }

  scope :expired, -> { where('deadline < ?', Time.now) }

  def self.accepted_file_types
    ['.pdf', '.tar.gz', '.cc', '.hh', '.m', '.mlx', '.zip']
  end

  validates :accepted_file_type,
            inclusion: { in: Assignment.accepted_file_types }

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
  	self.in?(lecture.current_assignments)
  end

  def previous?
  	self.in?(lecture.previous_assignments)
  end

  def previous
    siblings = lecture.assignments_by_deadline
    position = siblings.map(&:first).find_index(deadline)
    return unless position.positive?
    siblings[position - 1].second
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

  def has_documents?
    return false unless medium
    medium.video || medium.manuscript || medium.geogebra ||
      medium.external_reference_link.present? ||
      (medium.sort == 'Quiz' && medium.quiz_graph)
  end

  def self.accepted_mime_types
    { '.pdf' => ['application/pdf'],
      '.tar.gz' => ['application/gzip', 'application/x-gzip',
                    'application/x-gunzip', 'application/gzipped',
                    'application/gzip-compressed', 'application/x-compressed',
                    'application/x-compress', 'gzip/document',
                    'application/octet-stream'],
      '.cc' => ['text/*'],
      '.hh' => ['text/*'],
      '.m' => ['text/*'],
      '.mlx' => ['application/zip', 'application/x-zip',
                 'application/x-zip-compressed', 'application/octet-stream',
                 'application/x-compress', 'application/x-compressed',
                 'multipart/x-zip'],
      '.zip' => ['application/zip', 'application/x-zip',
                 'application/x-zip-compressed', 'application/octet-stream',
                 'application/x-compress', 'application/x-compressed',
                 'multipart/x-zip'] }
  end

  def self.non_inline_file_types
    ['.tar.gz', '.zip', '.mlx']
  end

  def accepted_mime_types
    Assignment.accepted_mime_types[accepted_file_type]
  end

  # some browsers have issues when the accept attribute of a file input
  # is set to .tar.gz
  # see e.g. https://bugs.chromium.org/p/chromium/issues/detail?id=521781
  def accepted_for_file_input
  	return accepted_file_type unless accepted_file_type == '.tar.gz'
  	'.gz'
  end
end

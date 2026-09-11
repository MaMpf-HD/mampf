class Assignment < ApplicationRecord
  include Assessment::Pointable

  attr_writer :requires_submission

  belongs_to :lecture, touch: true
  belongs_to :medium, optional: true
  has_many :submissions, dependent: :destroy

  before_save :inherit_deletion_date_from_lecture
  after_create :setup_assessment
  before_destroy :check_destructibility, prepend: true
  # A new sheet opens the list, and so does a deadline moved into the future:
  # the sheet is back in play, and a verdict that calls itself final over an
  # open sheet is what the list is there to prevent. A deadline moved within
  # the past is a correction and changes nothing.
  #
  # Rails keeps track of which action a record was committed for, so the
  # creation hangs on that. The deadline cannot: `saved_change_to_deadline?`
  # describes the last save alone, and a record may be saved twice inside one
  # transaction - moved and then renamed. The reason is noted where it happens
  # and kept until the commit.
  after_save :note_deadline_move
  after_create_commit :reopen_lecture_assignment_list
  after_update_commit :reopen_after_deadline_move, if: :deadline_moved_ahead?
  after_rollback :forget_deadline_move

  def requires_submission
    return assessment.requires_submission if assessment

    @requires_submission.nil? || @requires_submission
  end

  validates :title, uniqueness: { scope: [:lecture_id] }, presence: true
  validates :deadline, presence: true
  validate :deadline_not_in_past, if: -> { deadline_changed? }

  scope :active, -> { where(deadline: Time.zone.now..) }

  scope :expired, -> { where(deadline: ...Time.zone.now) }

  def self.accepted_file_types
    [".pdf", ".tar.gz", ".cc", ".hh", ".m", ".mlx", ".zip"]
  end

  validates :accepted_file_type,
            inclusion: { in: Assignment.accepted_file_types }
  validate :locked_fields_unchanged, if: -> { persisted? && past_deadline? }

  def submission(user)
    UserSubmissionJoin.where(submission: Submission.where(assignment: self),
                             user: user)
                      &.first&.submission
  end

  def submitter_ids
    UserSubmissionJoin.where(submission: submissions).pluck(:user_id).uniq
  end

  def submitters
    User.where(id: submitter_ids)
  end

  def past_deadline?
    deadline.present? && deadline < Time.zone.now
  end

  def active?
    Time.zone.now <= deadline
  end

  def semiactive?
    Time.zone.now <= friendly_deadline
  end

  def expired?
    !active?
  end

  def totally_expired?
    !semiactive?
  end
  alias grading_open? totally_expired?

  def in_grace_period?
    semiactive? && !active?
  end

  def friendly_deadline
    return deadline unless lecture.submission_grace_period

    deadline + lecture.submission_grace_period.minutes
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
    destruction_blockers.empty?
  end

  # Named the way Rosterable names them, so a view can ask any deletable thing
  # the same question. A sheet whose points are already in the pointbook goes
  # nowhere either, even if nobody uploaded anything.
  def destruction_blockers
    blockers = []
    blockers << :has_submissions if submissions.with_uploads.any?
    blockers << :has_grading_data if grading_data?
    blockers
  end

  def check_destructibility
    throw(:abort) unless destructible?
    true
  end

  def documents?
    return false unless medium

    medium.video || medium.manuscript || medium.geogebra ||
      medium.external_reference_link.present? ||
      (medium.sort == "Quiz" && medium.quiz_graph)
  end

  def self.accepted_mime_types
    { ".pdf" => ["application/pdf"],
      ".tar.gz" => ["application/gzip", "application/x-gzip",
                    "application/x-gunzip", "application/gzipped",
                    "application/gzip-compressed", "application/x-compressed",
                    "application/x-compress", "gzip/document",
                    "application/octet-stream"],
      ".cc" => ["text/*"],
      ".hh" => ["text/*"],
      ".m" => ["text/*"],
      ".mlx" => ["application/zip", "application/x-zip",
                 "application/x-zip-compressed", "application/octet-stream",
                 "application/x-compress", "application/x-compressed",
                 "multipart/x-zip"],
      ".zip" => ["application/zip", "application/x-zip",
                 "application/x-zip-compressed", "application/octet-stream",
                 "application/x-compress", "application/x-compressed",
                 "multipart/x-zip"] }
  end

  def self.non_inline_file_types
    [".tar.gz", ".zip", ".mlx"]
  end

  def accepted_mime_types
    Assignment.accepted_mime_types[accepted_file_type]
  end

  # some browsers have issues when the accept attribute of a file input
  # is set to .tar.gz
  # see e.g. https://bugs.chromium.org/p/chromium/issues/detail?id=521781
  def accepted_for_file_input
    return accepted_file_type unless accepted_file_type == ".tar.gz"

    ".gz"
  end

  private

    def locked_fields_unchanged
      return unless accepted_file_type_changed?

      errors.add(:accepted_file_type, :locked_after_deadline)
    end

    def deadline_not_in_past
      return if deadline.blank?

      errors.add(:deadline, :in_past) if deadline < Time.zone.now
    end

    def inherit_deletion_date_from_lecture
      self.deletion_date = lecture.submission_deletion_date
    end

    def grading_data?
      return false unless assessment

      participations = assessment.assessment_participations

      participations.exists?(status: [:reviewed, :exempt]) ||
        participations.where.not(points_total: nil).exists? ||
        participations.joins(:task_points).exists?
    end

    # A creation is not a move, and it has its own callback - noting it here
    # would leave the reason lying around for the next save to pick up.
    def note_deadline_move
      return if saved_change_to_id?
      return unless saved_change_to_deadline? && active?

      @deadline_moved_ahead = true
    end

    # Asked once, by the callback below, and forgotten in the asking: a reason
    # that outlived its transaction would reopen the list on the next save.
    def deadline_moved_ahead?
      @deadline_moved_ahead.tap { @deadline_moved_ahead = nil }
    end

    def forget_deadline_move
      @deadline_moved_ahead = nil
    end

    def reopen_after_deadline_move
      reopen_lecture_assignment_list
    end

    def setup_assessment
      ensure_pointbook!(requires_submission: requires_submission)
    end

    # Skip Lecture validations so an unrelated validation error cannot
    # leave assignments_complete_at set after an Assignment is added.
    def reopen_lecture_assignment_list
      return unless lecture&.assignments_complete?

      # rubocop:disable Rails/SkipsModelValidations
      lecture.update_column(:assignments_complete_at, nil)
      # rubocop:enable Rails/SkipsModelValidations
    end
end

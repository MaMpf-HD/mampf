class Assignment < ApplicationRecord
  include Assessment::Pointable

  attr_writer :requires_submission

  belongs_to :lecture, touch: true
  belongs_to :medium, optional: true
  has_many :submissions, dependent: :destroy

  before_save :inherit_deletion_date_from_lecture
  after_create :setup_assessment, if: -> { Flipper.enabled?(:assessment_grading) }
  before_destroy :check_destructibility, prepend: true

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

  # all user that are applicable for this assignment
  # -> all users that are in the lecture of this assignment
  def applicable_user_ids
    lecture.lecture_memberships.pluck(:user_id).uniq
  end

  def applicable_users
    User.where(id: applicable_user_ids)
  end

  def applicable_user_ids_tutorial(tutorial)
    tutorial.tutorial_memberships.pluck(:user_id).uniq
  end

  def applicable_user_ids_in_tutorials
    lecture.tutorials.joins(:tutorial_memberships)
           .pluck("tutorial_memberships.user_id").uniq
  end

  def applicable_user_ids_not_in_tutorials
    applicable_user_ids - applicable_user_ids_in_tutorials
  end

  def applicable_users_not_in_tutorials
    User.where(id: applicable_user_ids_not_in_tutorials)
  end

  def non_submitter_ids_in_tutorials
    applicable_user_ids_in_tutorials - submitter_ids
  end

  def non_submitters_in_tutorials
    User.where(id: non_submitter_ids_in_tutorials)
  end

  # non submitters of tutorial = users in tutorial_memberships \ submitters of assignment
  def non_submitters_in_tutorial(tutorial)
    User.joins(:tutorial_memberships)
        .where(tutorial_memberships: { tutorial_id: tutorial.id })
        .where.not(id: submitter_ids)
        .order(:name)
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

  def assessable?
    assessment != nil
  end

  def in_grace_period?
    semiactive? && !active?
  end

  def friendly_deadline
    return deadline unless lecture.submission_grace_period

    deadline + lecture.submission_grace_period.minutes
  end

  def current?
    in?(lecture.current_assignments)
  end

  def previous?
    in?(lecture.previous_assignments)
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
    non_destructible_reason.nil?
  end

  def non_destructible_reason
    return :has_submissions if submissions.proper.any?

    return :has_grading_data if grading_data?

    nil
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

    def setup_assessment
      ensure_pointbook!(requires_submission: requires_submission)
    end
end

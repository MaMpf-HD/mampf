class Assignment < ApplicationRecord
  include Assessment::Assessable

  belongs_to :lecture, touch: true
  belongs_to :medium, optional: true
  has_many :submissions, dependent: :destroy

  after_create :setup_assessment, if: -> { Flipper.enabled?(:assessment_grading) }
  before_destroy :check_destructibility, prepend: true

  validates :title, uniqueness: { scope: [:lecture_id] }, presence: true
  validates :deadline, presence: true
  validates :deletion_date, presence: true
  validate :deletion_date_cannot_be_in_the_past

  def deletion_date_cannot_be_in_the_past
    return unless deletion_date.present? && deletion_date < Time.zone.now.to_date

    errors.add(:deletion_date, I18n.t("activerecord.errors.models." \
                                      "assignment.attributes.deletion_date." \
                                      "in_past"))
  end

  scope :active, -> { where(deadline: Time.zone.now..) }

  scope :expired, -> { where(deadline: ...Time.zone.now) }

  def self.accepted_file_types
    [".pdf", ".tar.gz", ".cc", ".hh", ".m", ".mlx", ".zip"]
  end

  validates :accepted_file_type,
            inclusion: { in: Assignment.accepted_file_types }

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
    submissions.proper.none?
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

  def localized_deletion_date
    deletion_date.strftime(I18n.t("date.formats.concise"))
  end

  def seed_participations_from_roster!
    return unless assessment

    # Users can only be in one tutorial per lecture (enforced by
    # TutorialMembership validation), so each user_id appears at most once
    memberships = TutorialMembership
                  .where(tutorial_id: lecture.tutorial_ids)
                  .pluck(:user_id, :tutorial_id)

    tutorial_mapping = memberships.to_h
    user_ids = memberships.map(&:first)

    assessment.seed_participations_from!(
      user_ids: user_ids,
      tutorial_mapping: tutorial_mapping
    )
  end

  private

    def setup_assessment
      ensure_assessment!(
        requires_points: true,
        requires_submission: true,
        due_at: deadline
      )
      seed_participations_from_roster!
    end
end

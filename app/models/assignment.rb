class Assignment < ApplicationRecord
  include Assessment::Pointable

  # Prefix the enum methods to avoid colliding with Kernel#test.
  enum :kind, { homework: 0, test: 1 }, prefix: true

  TEST_WEEK_COUNTS = (1..6)

  # The form posts "1"/"0"; as strings both would count as true.
  def requires_submission=(value)
    @requires_submission = ActiveModel::Type::Boolean.new.cast(value)
  end

  belongs_to :lecture, touch: true
  belongs_to :medium, optional: true
  has_many :submissions, dependent: :destroy
  has_many :sightings, class_name: "AssignmentSighting", dependent: :destroy

  before_validation :end_test_week, if: -> { kind_test? && deadline_changed? }
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
    return false if kind_test?
    return assessment.requires_submission if assessment

    @requires_submission.nil? || @requires_submission
  end

  validates :title, uniqueness: { scope: [:lecture_id] }, presence: true
  validates :deadline, presence: true
  validate :deadline_not_in_past, if: -> { kind_homework? && deadline_changed? }
  validate :test_period_not_before_last,
           if: -> { kind_test? && (deadline_changed? || test_week_count_changed?) }
  validates :test_week_count, inclusion: { in: TEST_WEEK_COUNTS }, if: :kind_test?
  # Homework has no test weeks; a request that sets `test_week_count` on one
  # is refused rather than ignored.
  validates :test_week_count, inclusion: { in: [1] }, unless: :kind_test?
  # Changing kind would reinterpret existing submissions and grading data.
  validate :kind_immutable, if: -> { persisted? && kind_changed? }
  # The form offers a test no sheet to attach; a request that names one
  # anyway is refused rather than quietly obeyed.
  validates :medium_id, absence: true, if: :kind_test?

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

  # A team formed without a file has handed nothing in; its members still
  # need their row in the tutor's table.
  def submitter_ids
    UserSubmissionJoin.where(submission: submissions.proper).pluck(:user_id).uniq
  end

  def submitters
    User.where(id: submitter_ids)
  end

  def user_ids_in_lecture_from_memberships
    lecture.lecture_memberships.pluck(:user_id).uniq
  end

  def applicable_users_not_in_tutorials
    User.where(id: applicable_user_ids_not_in_tutorials_from_memberships)
  end

  def non_submitters_in_tutorials
    if past_deadline?
      non_submitters_in_tutorials_postdeadline
    else
      non_submitters_in_tutorials_predeadline
    end
  end

  def non_submitters_in_tutorial(tutorial)
    if past_deadline?
      non_submitters_in_tutorial_postdeadline(tutorial)
    else
      non_submitters_in_tutorial_predeadline(tutorial)
    end
  end

  def past_deadline?
    deadline.present? && deadline < Time.zone.now
  end

  def active?
    Time.zone.now <= deadline
  end

  # A test's deadline is the end of its last week; the groups write it during
  # its weeks, each in its own session, so marking opens with the first week
  # and not after the last. Homework is marked once its deadline and grace
  # period are over.
  def grading_open?
    return Time.zone.now >= test_week.in_time_zone if kind_test?

    totally_expired?
  end

  # Returns the Monday of the test's first week.
  def test_week
    first_test_week(deadline, test_week_count)
  end

  # Invalid dates must reach the deadline presence validation, not raise.
  # The test keeps its number of weeks.
  def test_week=(monday)
    first = Time.zone.parse(monday.to_s)
    self.deadline = first && test_deadline_from(first)
  rescue ArgumentError
    self.deadline = nil
  end

  # The test keeps its first week, whichever of the two the form sends first.
  # `AssignmentsController#create` assigns `kind` last, so the record may
  # still be homework here; a count it already has leaves the deadline alone.
  def test_week_count=(count)
    first = test_week
    before = test_week_count
    super
    self.deadline = test_deadline_from(first) if first && test_week_count != before
  end

  def test_period
    return unless deadline

    test_week..deadline.to_date
  end

  # Reads the term itself, not Lecture#begin_date, which falls back to
  # Term.active, and that may be absent too. The term counts as over once it
  # ended before this week; otherwise, in the week after it, the list would
  # stop at last week and miss this week, a new test's default.
  def test_week_choices
    this_week = Time.zone.today.beginning_of_week
    first = [lecture.term&.begin_date, earliest_test_week].compact.max.beginning_of_week
    term_end = lecture.term&.end_date
    last = (term_end && term_end >= this_week ? term_end : this_week + 6.months).beginning_of_week
    weeks = []
    monday = first
    while monday <= last
      weeks << monday
      monday += 7
    end
    weeks |= [test_week] if deadline
    weeks.sort
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

  def assessable?
    assessment != nil
  end

  def in_grace_period?
    semiactive? && !active?
  end

  # No grace period for a test: nothing is handed in late.
  def friendly_deadline
    return deadline if kind_test? || lecture.submission_grace_period.nil?

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

    # Ending before last week would make the test due for the groups that are
    # still to write it.
    def test_period_not_before_last
      return if deadline.blank?

      if test_week_moved? && test_week < earliest_test_week
        errors.add(:test_week, :before_last_week)
      elsif deadline.to_date < earliest_test_week
        errors.add(:test_week_count, :ends_before_last_week)
      end
    end

    # A running test keeps a start weeks back while it is made longer or
    # shorter; only a start that moves is held to last week.
    def test_week_moved?
      return true if new_record?

      test_week != first_test_week(deadline_was, test_week_count_was)
    end

    def first_test_week(due, count)
      return unless due

      due.to_date.beginning_of_week - (count.to_i - 1).weeks
    end

    def test_deadline_from(first)
      first.in_time_zone.end_of_week + (test_week_count.to_i - 1).weeks
    end

    # A test written unannounced can only be set up once its last group has
    # sat it, and that may be on the last day of its week.
    def earliest_test_week
      Time.zone.today.prev_week
    end

    def kind_immutable
      errors.add(:kind, :immutable)
    end

    def end_test_week
      self.deadline = deadline.end_of_week if deadline
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

    def non_submitters_in_tutorial_predeadline(tutorial)
      User.where(id: non_submitter_ids_in_tutorial_from_memberships(tutorial))
    end

    def non_submitters_in_tutorial_postdeadline(tutorial)
      ids = non_submitter_ids_in_tutorial_from_participations(tutorial) |
            non_submitter_ids_in_tutorial_from_memberships(tutorial)
      User.where(id: ids)
    end

    def non_submitters_in_tutorials_predeadline
      User.where(id: non_submitter_ids_in_tutorials_from_memberships)
    end

    def non_submitters_in_tutorials_postdeadline
      ids = non_submitter_ids_in_tutorials_from_participations |
            non_submitter_ids_in_tutorials_from_memberships
      User.where(id: ids)
    end

    def applicable_user_ids_not_in_tutorials_from_memberships
      user_ids_in_lecture_from_memberships - user_ids_in_tutorials_from_memberships
    end

    def non_submitter_ids_in_tutorials_from_memberships
      user_ids_in_tutorials_from_memberships - submitter_ids
    end

    def non_submitter_ids_in_tutorials_from_participations
      user_ids_in_tutorials_from_participations - submitter_ids
    end

    def non_submitter_ids_in_tutorial_from_memberships(tutorial)
      user_ids_in_tutorial_from_memberships(tutorial) - submitter_ids
    end

    def non_submitter_ids_in_tutorial_from_participations(tutorial)
      user_ids_in_tutorial_from_participations(tutorial) - submitter_ids
    end

    def user_ids_in_tutorials_from_memberships
      lecture.tutorials.joins(:tutorial_memberships)
             .pluck("tutorial_memberships.user_id").uniq
    end

    def user_ids_in_tutorials_from_participations
      return [] if assessment.blank?

      tutorial_ids = lecture.tutorials.pluck(:id)
      Assessment::Participation
        .where(assessment_id: assessment.id, tutorial_id: tutorial_ids)
        .distinct
        .pluck(:user_id)
    end

    def user_ids_in_tutorial_from_memberships(tutorial)
      tutorial.tutorial_memberships.pluck("user_id").uniq
    end

    def user_ids_in_tutorial_from_participations(tutorial)
      return [] if assessment.blank?

      Assessment::Participation
        .where(assessment_id: assessment.id, tutorial_id: tutorial.id)
        .distinct
        .pluck(:user_id)
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

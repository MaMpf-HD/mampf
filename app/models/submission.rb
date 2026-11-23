class Submission < ApplicationRecord
  belongs_to :tutorial
  belongs_to :assignment

  has_many :user_submission_joins, dependent: :destroy
  has_many :users, through: :user_submission_joins

  self.implicit_order_column = "created_at"

  MEMBER_SEARCH_MIN_LENGTH = 2

  include SubmissionUploader[:manuscript]
  include CorrectionUploader[:correction]

  scope :proper, -> { where.not(manuscript_data: nil) }

  # Submissions that still hold a file. Detaching a manuscript leaves the
  # tutor's correction behind, which #proper does not see - and a deleted
  # correction cannot be restored.
  scope :with_uploads, lambda {
    where.not(manuscript_data: nil).or(where.not(correction_data: nil))
  }

  validate :matching_lecture, if: :tutorial

  before_save :set_corrected_at, if: :correction_data_changed?
  before_create :set_token

  delegate :assessment, to: :assignment

  def participations
    return nil unless assignment.assessable?

    found = Assessment::Participation.where(assessment: assignment.assessment, user: users)
                                     .index_by(&:user_id)
    users.map { |user| found[user.id] }
  end

  # Once anybody on the team has been marked, the team is closed to
  # late-comers: joining would hand them points they were not there for.
  # Until then, the code is the team's own word that somebody belongs.
  def marked?
    return false unless assignment.assessable?

    participations.compact.any? { |participation| assessment.marked?(participation) }
  end

  def partners_of_user(user)
    return unless user.in?(users)

    users - [user]
  end

  def team
    users.map(&:tutorial_name).natural_sort.join(", ")
  end

  def member_tutorial_ids
    TutorialMembership.where(user_id: user_ids, lecture_id: assignment.lecture_id)
                      .distinct.pluck(:tutorial_id)
  end

  # Whom a tutor may put on the team: a member of its tutorial, or of any of
  # the lecture's tutorials where teams may span them, as a join by code
  # allows.
  def member_candidates
    lecture = assignment.lecture
    memberships = if lecture.cross_tutorial_teams?
      TutorialMembership.where(lecture_id: lecture.id)
    else
      TutorialMembership.where(tutorial_id: tutorial_id)
    end
    User.where(id: memberships.select(:user_id))
  end

  # The candidates from the lecture's other tutorials whose shown name
  # matches, on no team for the sheet yet; the group's own are on the page
  # already, also anybody who moved away and left their row with it. A shorter
  # query would match much of a large lecture. Somebody marked on a row of
  # their own is done with the sheet.
  def member_candidates_elsewhere(query)
    return User.none if query.length < MEMBER_SEARCH_MIN_LENGTH

    joined = UserSubmissionJoin.where(submission: assignment.submissions)
    marked = Assessment::Participation.marked.where(assessment: assessment)
    member_candidates
      .where.not(id: TutorialMembership.where(tutorial_id: tutorial_id).select(:user_id))
      .where.not(id: assignment.non_submitters_in_tutorial(tutorial).select(:id))
      .where.not(id: joined.select(:user_id))
      .where.not(id: marked.select(:user_id))
      .where("#{User::SHOWN_NAME_SQL} ILIKE :q",
             q: "%#{User.sanitize_sql_like(query)}%")
      .by_last_name
  end

  # Whether a tutor may put somebody on the team: not while the hand-in is
  # rejected as late. A deadline moved past it since makes it count again,
  # as it does for marking.
  def takes_members?
    !(too_late? && accepted == false)
  end

  # Once a team has points or a correction, the tutorial that marked it
  # keeps it.
  def movable?
    correction.blank? && !marked?
  end

  # A team of one sits in another tutorial when its member moved after
  # handing in; its tutor hands it over like any other. Until the grace
  # period is over, a join or a leave still places the team, not a tutor.
  def hand_over_targets
    return Tutorial.none unless movable? && assignment.totally_expired?

    Tutorial.where(id: member_tutorial_ids - [tutorial_id]).order(:title)
  end

  # A mixed team goes to the member tutorial with the fewest hand-ins, so the
  # uploader does not choose the tutor. A tutor's hand-over holds while a
  # member sits in that tutorial, even across a leave and a rejoin.
  # Once the grace period is over a team stays where it is: its tutor may be
  # marking it from a bulk download already, which leaves no trace here.
  # Only a hand-over moves it then.
  def place_team!(tutorials_before)
    return if assignment.totally_expired?

    with_team_locked do
      next unless movable?

      tutorials = member_tutorial_ids
      next if tutorials.empty?

      file_under!(placement_for(tutorials, tutorials_before))
    end
  end

  def hand_over!(target)
    with_team_locked do
      next false unless target&.in?(hand_over_targets)

      update!(handed_over_to_id: target.id)
      file_under!(target.id)
      true
    end
  end

  def manuscript_filename
    return if manuscript.blank?

    manuscript.metadata["filename"]
  end

  def manuscript_size
    return if manuscript.blank?

    manuscript.metadata["size"]
  end

  def manuscript_mime_type
    return if manuscript.blank?

    manuscript.metadata["mime_type"]
  end

  def correction_filename
    return if correction.blank?

    correction.metadata["filename"]
  end

  def correction_mime_type
    return if correction.blank?

    correction.metadata["mime_type"]
  end

  def correction_size
    return if correction.blank?

    correction.metadata["size"]
  end

  def invited_users
    User.where(id: invited_user_ids)
  end

  def self.generate_token
    loop do
      random_token = SecureRandom.base58(6)
      break random_token unless Submission.exists?(token: random_token)
    end
  end

  def admissible_invitees(user)
    user.submission_partners(assignment.lecture) - users
  end

  def in_time?
    (last_modification_by_users_at || created_at) <= assignment.deadline
  end

  def too_late?
    !in_time?
  end

  def not_updatable?
    return false if assignment.active?

    assignment.totally_expired? || correction.present? || accepted == false
  end

  def valid_for_marking?
    in_time? || accepted == true
  end

  # def file_path(downloadable)
  #	return unless manuscript
  # 	manuscript.to_io.path
  # end

  # def correction_file_path
  #  return unless correction
  #  correction.to_io.path
  # end

  def filename_for_bulk_download(end_of_file = "")
    start_str = "#{team.first(180)}-#{last_modification_by_users_at.strftime("%F-%H%M")}"
    too_late_str = too_late? ? "-LATE" : ""
    id_str = "-ID-#{id}"
    end_of_file_str = "#{end_of_file}#{assignment.accepted_file_type}"

    "#{start_str}#{too_late_str}#{id_str}#{end_of_file_str}"
      .gsub(%r{[\x00/\\:*?"<>|]}, "_")
      .gsub(%r{^.*(\\|/)}, "")
      # Strip out the non-ascii characters
      .gsub(/[^0-9A-Za-z.-]/, "_")
  end

  def self.zip(submissions, downloadables, end_of_file = "")
    begin
      archived_filestream = Zip::OutputStream.write_buffer do |stream|
        submissions.zip(downloadables).each do |s, d|
          stream.put_next_entry(s.filename_for_bulk_download(end_of_file))
          stream.write(File.read(d.to_io.path))
        end
      end
      archived_filestream.rewind
    rescue StandardError => e
      archived_filestream = e.message
    end
    archived_filestream
  end

  def self.zip_submissions!(tutorial, assignment)
    submissions = Submission.where(tutorial: tutorial,
                                   assignment: assignment).proper
    manuscripts = submissions.collect do |s|
      s.manuscript.presence
    end
    zip(submissions, manuscripts)
  end

  def self.zip_corrections!(tutorial, assignment)
    submissions = Submission.where(tutorial: tutorial,
                                   assignment: assignment).proper
    corrections = submissions.collect do |s|
      s.correction.presence
    end

    zip(submissions, corrections, "-correction")
  end

  ###
  # Checks size and if filetype is acceptable
  ###
  def check_file_properties_any(metadata, sort)
    errors = []
    if sort == :submission && metadata["size"] > 10 * 1024 * 1024
      errors.push(I18n.t("submission.manuscript_size_too_big",
                         max_size: "10 MB"))
    end
    if sort == :correction && metadata["size"] > CorrectionUploader::MAX_SIZE
      errors.push(I18n.t("submission.manuscript_size_too_big",
                         max_size: "#{CorrectionUploader::MAX_SIZE / (1024 * 1024)} MB"))
    end
    file_name = metadata["filename"]
    uploader = sort == :correction ? CorrectionUploader : SubmissionUploader
    file_type = File.extname(file_name)
    unless uploader.allowed_extension?(file_name)
      errors.push(I18n.t("submission.wrong_file_type",
                         file_type: file_type,
                         accepted_file_type:
                           uploader.accepted_extension_list))
    end
    if errors.blank? &&
       !uploader.allowed_mime_type?(filename: file_name,
                                    mime_type: metadata["mime_type"])
      errors.push(I18n.t("submission.wrong_mime_type",
                         mime_type: metadata["mime_type"],
                         accepted_mime_types:
                           uploader.accepted_mime_types_for(file_name).join(", ")))
    end
    return {} if errors.blank?

    { sort => errors }
  end

  def check_file_properties(metadata, sort)
    errors = []
    if sort == :submission && metadata["size"] > 10 * 1024 * 1024
      errors.push(I18n.t("submission.manuscript_size_too_big",
                         max_size: "10 MB"))
    end
    if sort == :correction && metadata["size"] > CorrectionUploader::MAX_SIZE
      errors.push(I18n.t("submission.manuscript_size_too_big",
                         max_size: "#{CorrectionUploader::MAX_SIZE / (1024 * 1024)} MB"))
    end
    file_name = metadata["filename"]
    file_type = File.extname(file_name)
    if file_type != assignment.accepted_file_type &&
       assignment.accepted_file_type != ".tar.gz"
      errors.push(I18n.t("submission.wrong_file_type",
                         file_type: file_type,
                         accepted_file_type: assignment.accepted_file_type))
    end
    if assignment.accepted_file_type == ".tar.gz"
      if file_type == ".gz"
        reduced_type = File.extname(File.basename(file_name, ".gz"))
        if reduced_type != ".tar"
          errors.push(I18n.t("submission.wrong_file_type",
                             file_type: ".gz",
                             accepted_file_type: ".tar.gz"))
        end
      else
        errors.push(I18n.t("submission.wrong_file_type",
                           file_type: file_type,
                           accepted_file_type: ".tar.gz"))
      end
    end
    if (!assignment.accepted_file_type.in?([".cc", ".hh", ".m"]) &&
      !metadata["mime_type"].in?(assignment.accepted_mime_types)) ||
       (assignment.accepted_file_type.in?([".cc", ".hh", ".m"]) &&
         !metadata["mime_type"].starts_with?("text/") &&
          metadata["mime_type"] != "application/octet-stream")
      errors.push(I18n.t("submission.wrong_mime_type",
                         mime_type: metadata["mime_type"],
                         accepted_mime_types: assignment.accepted_mime_types
                                                        .join(", ")))
    end
    return {} if errors.blank?

    { sort => errors }
  end

  def self.bulk_corrections!(tutorial, assignment, files)
    submissions = Submission.where(tutorial: tutorial,
                                   assignment: assignment).proper
    report = { successful_saves: [], submissions: submissions.size,
               invalid_filenames: [], invalid_id: [], elsewhere: [], in_subfolder: [],
               no_decision: [], rejected: [], invalid_file: [] }
    begin
      files.each do |file_shrine|
        filename = file_shrine["metadata"]["filename"]
        unless "-ID-".in?(filename)
          report[:invalid_filenames].push(filename)
          next
        end
        submission_id = File.basename(filename.split("-ID-").last,
                                      File.extname(filename.split("-ID-").last))
        # Scope the lookup to this tutorial+assignment so an id parsed from the
        # uploaded filename cannot target a submission in another tutorial.
        submission = submissions.find_by(id: submission_id)
        unless submission
          elsewhere = known_elsewhere(tutorial, assignment, submission_id)
          elsewhere ? report_elsewhere(report, elsewhere) : report[:invalid_id].push(filename)
          next
        end
        if submission.too_late? && submission.accepted.nil?
          report[:no_decision].push(submission.team)
          next
        end
        if submission.too_late? && submission.accepted == false
          report[:rejected].push(submission.team)
          next
        end
        moved = submission.with_lock do
          next true unless submission.tutorial_id == tutorial.id

          submission.update(correction: file_shrine.to_json)
          false
        end
        if moved
          report_elsewhere(report, submission)
          next
        end
        unless submission.valid?
          report[:invalid_file].push(filename)
          next
        end
        report[:successful_saves].push(submission)
      end
    rescue StandardError => e
      report[:errors] = e.message.to_s
    end
    report
  end

  # A hand-in of the same sheet that another tutorial has now and that may
  # have been in this tutorial's bundle: one handed over, or one of a team
  # with somebody in this tutorial. Any other id stays invalid, so the report
  # does not name a team the tutor has nothing to do with.
  def self.known_elsewhere(tutorial, assignment, submission_id)
    elsewhere = where(assignment: assignment).includes(:users, tutorial: :tutors)
                                             .find_by(id: submission_id)
    return unless elsewhere
    return elsewhere if elsewhere.handed_over_to_id?

    elsewhere if elsewhere.member_tutorial_ids.include?(tutorial.id)
  end

  # Names the team and the tutorial that has its hand-in now, so the
  # correction can go there. Nothing is written on it.
  def self.report_elsewhere(report, submission)
    report[:elsewhere].push([submission.team, submission.tutorial.title_with_tutors])
  end
  private_class_method :known_elsewhere, :report_elsewhere

  private

    # Takes the submission first and the team's participations second, the
    # order a team's point entry takes them in: a move and a point entry or
    # correction then wait for each other, and each sees the other's result.
    def with_team_locked
      with_lock do
        if assignment.assessable?
          assessment.assessment_participations.where(user_id: user_ids).lock.load
        end
        yield
      end
    end

    def placement_for(tutorials, tutorials_before)
      return handed_over_to_id if handed_over_to_id.in?(tutorials)
      return tutorials.first if tutorials.one?
      return tutorial_id if tutorials_before.many? && tutorial_id.in?(tutorials)

      least_busy(tutorials)
    end

    # The participations move with the submission, so the marking backlog
    # counts the team in the tutorial that marks it.
    def file_under!(target_id)
      update!(tutorial_id: target_id) unless tutorial_id == target_id
      return unless assignment.assessable?

      assessment.assessment_participations.where(user_id: user_ids)
                .update_all(tutorial_id: target_id, updated_at: Time.current) # rubocop:disable Rails/SkipsModelValidations
    end

    def least_busy(tutorials)
      counts = Submission.proper.where(assignment: assignment, tutorial_id: tutorials)
                         .where.not(id: id).group(:tutorial_id).count
      tutorials.min_by { |tutorial| [counts.fetch(tutorial, 0), tutorial] }
    end

    def matching_lecture
      return true if tutorial&.lecture == assignment&.lecture

      errors.add(:tutorial, :lecture_not_matching)
    end

    def set_token
      self.token = Submission.generate_token
    end

    def set_corrected_at
      self.corrected_at = correction.present? ? Time.current : nil
    end
end

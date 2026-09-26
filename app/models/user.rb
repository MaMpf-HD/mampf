# User class
class User < ApplicationRecord
  include ApplicationHelper

  class IncompatibleTypeError < StandardError; end

  CURRENT_PASSWORD_POLICY_VERSION = 1
  PERSONAL_DATA_FIELDS = [:first_name, :last_name, :matriculation_number, :program_id,
                          :uni_id].freeze
  # What a group or an exam lists a student by: once saved, only the support
  # changes it. Program and Uni ID stay the user's to change.
  LOCKED_PERSONAL_DATA_FIELDS = [:first_name, :last_name, :matriculation_number].freeze

  # use devise for authentification, include the following modules
  devise :database_authenticatable, :registerable, :trackable,
         :recoverable, :rememberable, :validatable, :confirmable, :lockable

  # a user has many bookmarked lectures (formerly: subscribed lectures)
  has_many :lecture_bookmarks, dependent: :destroy
  has_many :dashboard_card_styles, class_name: "Dashboard::CardStyle", dependent: :delete_all
  has_many :lectures, -> { distinct }, through: :lecture_bookmarks

  # Roster memberships
  has_many :lecture_memberships, dependent: :destroy
  has_many :assignment_sightings, dependent: :destroy
  has_many :enrolled_lectures, through: :lecture_memberships, source: :lecture

  has_many :tutorial_memberships, dependent: :destroy
  has_many :enrolled_tutorials, through: :tutorial_memberships, source: :tutorial

  has_many :cohort_memberships, dependent: :destroy
  has_many :cohorts, through: :cohort_memberships

  has_many :assessment_participations,
           dependent: :destroy,
           class_name: "Assessment::Participation",
           inverse_of: :user

  # a user has many favorite lectures
  has_many :user_favorite_lecture_joins, dependent: :destroy
  has_many :favorite_lectures, -> { distinct },
           through: :user_favorite_lecture_joins,
           source: :lecture

  # a user has many courses as an editor
  has_many :editable_user_joins, dependent: :destroy
  has_many :edited_courses, through: :editable_user_joins,
                            source: :editable, source_type: "Course"

  # a user has many lectures as an editor
  has_many :edited_lectures, through: :editable_user_joins,
                             source: :editable, source_type: "Lecture"

  # a user has many media as an editor
  has_many :edited_media, through: :editable_user_joins,
                          source: :editable, source_type: "Medium"

  # a user has many lectures as a teacher
  has_many :given_lectures,
           class_name: "Lecture",
           foreign_key: "teacher_id",
           inverse_of: :teacher

  # a user has many tutorials as a tutor

  has_many :tutor_tutorial_joins,
           foreign_key: "tutor_id",
           dependent: :destroy,
           inverse_of: :tutor
  has_many :given_tutorials, -> { order(:title) },
           through: :tutor_tutorial_joins, source: :tutorial

  # a user has many given talks
  has_many :speaker_talk_joins,
           foreign_key: "speaker_id",
           dependent: :destroy,
           inverse_of: :speaker
  has_many :talks, through: :speaker_talk_joins

  # a user has many notifications as recipient
  has_many :notifications,
           foreign_key: "recipient_id",
           inverse_of: :recipient

  # a user has many announcements as announcer
  has_many :announcements,
           foreign_key: "announcer_id",
           dependent: :destroy,
           inverse_of: :announcer

  # a user has many submissions (of assignments)
  has_many :user_submission_joins, dependent: :destroy
  has_many :submissions, through: :user_submission_joins

  # a user has many quiz certificates that are obtained by solving quizzes
  # and claiming the certificate
  has_many :quiz_certificates, dependent: :destroy

  # a user has many user registrations for registration campaigns
  has_many :user_registrations,
           class_name: "Registration::UserRegistration",
           dependent: :destroy
  has_many :registration_campaigns, through: :user_registrations
  has_many :registration_items, through: :user_registrations

  # a user has a watchlist with watchlist_entries
  has_many :watchlists, dependent: :destroy

  has_many :feedbacks, dependent: :destroy

  # a user has redemptions of vouchers
  has_many :redemptions, dependent: :destroy

  include ProfileimageUploader[:image]

  # if a homepage is given it should at leat be a valid address
  validates :homepage, http_url: true, if: :homepage?

  validates :locale, inclusion: { in: I18n.available_locales.map(&:to_s) },
                     if: :locale?

  validates :password, password_strength: true, allow_blank: true,
                       if: -> { Rails.configuration.x.password_strength_checks }

  # Devise hashes the same password with a fresh salt, so re-entering the old
  # one would pass as a change and mark the account compliant.
  validate :password_differs_from_current,
           if: -> { password.present? && password_change_required? }

  # a user needs to give a display name
  validates :name, presence: true, if: :persisted?

  normalizes :first_name, :last_name, with: ->(value) { value.squish.presence }
  normalizes :matriculation_number, with: ->(value) { value.gsub(/\s/, "").presence }
  normalizes :uni_id, with: ->(value) { value.strip.downcase.presence }

  validates :matriculation_number, uniqueness: true, format: { with: /\A\d{7}\z/ },
                                   allow_nil: true
  validates :uni_id, uniqueness: true, format: { with: /\A[a-z]{2}\d{3}\z/ }, allow_nil: true
  validates :first_name, :last_name, presence: true, on: :personal_data
  validates :matriculation_number, presence: true, on: :personal_data,
                                   unless: :no_matriculation_number
  validates :personal_data_confirmation, acceptance: { allow_nil: false }, on: :personal_data,
                                         if: :locked_personal_data_changed?

  # The student has no matriculation number yet (first weeks, guest student);
  # the empty field may be filled in later.
  attribute :no_matriculation_number, :boolean, default: false

  # Empty for "Other degree" or "Other subject", or while the user has not
  # answered yet.
  belongs_to :program, optional: true
  PROGRAM_PRELOAD = { program: [:translations, { subject: :translations }] }.freeze
  validate :program_offered_to_students, if: :program_id_changed?

  before_save :track_password_change

  # set some default values before saving if they are not set
  before_save :set_defaults

  # a user must consent to the privacy policy to exist
  validates :consents, acceptance: true, on: :create

  # add timestamp for DSGVO consent
  before_save :set_consented_at, if: -> { consents? && consented_at.nil? }
  before_destroy :destroy_single_submissions, prepend: true

  attr_accessor :skip_destroy_talk_media

  before_destroy :destroy_talk_media_upon_user_deletion, prepend: true,
                                                         unless: :skip_destroy_talk_media

  # users can comment stuff
  acts_as_commontator

  scope :email_for_submission_upload,
        -> { where(email_for_submission_upload: true) }
  scope :email_for_submission_removal,
        -> { where(email_for_submission_removal: true) }
  scope :email_for_submission_join,
        -> { where(email_for_submission_join: true) }
  scope :email_for_submission_leave,
        -> { where(email_for_submission_leave: true) }
  scope :email_for_correction_upload,
        -> { where(email_for_correction_upload: true) }
  scope :email_for_submission_decision,
        -> { where(email_for_submission_decision: true) }
  scope :no_tutorial_name,
        -> { where(name_in_tutorials: nil) }

  def password_change_required?
    password_policy_version < CURRENT_PASSWORD_POLICY_VERSION
  end

  # Scopes for usage in the UserCleaner
  scope :confirmed, -> { where.not(confirmed_at: nil) }
  scope :unconfirmed, -> { where(confirmed_at: nil) }
  scope :no_sign_in_data, -> { where(current_sign_in_at: nil) }
  scope :active_recently, ->(threshold) { where(current_sign_in_at: threshold.ago..) }
  scope :inactive_for, ->(threshold) { where(current_sign_in_at: ...threshold.ago) }
  scope :confirmation_sent_before, ->(threshold) { where(confirmation_sent_at: ...threshold.ago) }

  # returns the array of all teachers
  def self.teachers
    User.where(id: Lecture.distinct.select(:teacher_id))
  end

  def self.select_teachers
    User.teachers.pluck(:name, :id).natural_sort_by(&:first)
  end

  # returns the array of all editors minus those that are only editors of talks
  def self.proper_editors
    talk_media_ids = Medium.where(teachable_type: "Talk").pluck(:id)
    talk_media_joins = EditableUserJoin.where(editable_type: "Medium",
                                              editable_id: talk_media_ids)
    User.where(id: EditableUserJoin.where.not(id: talk_media_joins.pluck(:id))
                                   .pluck(:user_id).uniq)
  end

  def self.name_or_email_like(search_string)
    where("name ILIKE ? OR email ILIKE ?",
          "%#{search_string}%",
          "%#{search_string}%")
  end

  def self.name_in_tutorials_or_email_like(search_string)
    where("name_in_tutorials ILIKE ? OR email ILIKE ?",
          "%#{search_string}%",
          "%#{search_string}%")
  end

  def self.preferred_name_or_email_like(search_string)
    return User.none unless search_string
    return User.none unless search_string.length >= 2

    where(name_in_tutorials: [nil, ""]).name_or_email_like(search_string)
                                       .or(where.not(name_in_tutorials: [nil,
                                                                         ""])
               .name_in_tutorials_or_email_like(search_string))
  end

  def self.values_for_select
    pluck(:id, :name, :name_in_tutorials, :email)
      .map do |u|
      { value: u.first,
        text: "#{u.third.presence || u.second} (#{u.fourth})" }
    end
  end

  def courses
    Course.where(id: lectures.pluck(:course_id).uniq)
  end

  # related courses for user are
  # - all courses that the user has subscribe to plus their preceding courses
  #   (if subscription type is 1)
  # - all courses (if subscription type is 2)
  # - all courses that the user has subscribed to (if subscription type is 3)
  def related_courses(overrule_subscription_type: false)
    return if subscription_type.nil?

    selection_type = overrule_subscription_type || subscription_type
    return Course.where(id: preceding_course_ids).includes(:lectures) if selection_type == 1
    return Course.includes(:lectures) if selection_type == 2

    courses
  end

  # array of all administrated courses together with their ids
  # administrated courses are:
  # - all courses if the user is an admin,
  # - all courses edited by the user otherwise
  def select_administrated_courses
    administrated_courses.map { |c| [c.title, c.id] }
  end

  def administrated_courses
    admin ? Course.all : edited_courses
  end

  # related lectures are lectures associated to related courses (see above)
  def related_lectures
    Lecture.where(course: related_courses)
  end

  # returns ARel of all those tags from the given tags that belong to
  # the user's related lectures
  def filter_tags(tags)
    Tag.where(id: tags.select do |t|
                    t.in_lectures?(related_lectures) ||
                                      t.in_courses?(related_courses)
                  end
                      .map(&:id))
  end

  # returns ARel of all those lectures from the given lectures that belong to
  # the user's related lectures
  def filter_lectures(lectures)
    Lecture.where(id: lectures.pluck(:id) & related_lectures.pluck(:id))
  end

  # returns ARel of all those media from the given media that are related to
  # the user's related lectures
  def filter_media(media)
    media.where(teachable: related_lectures)
         .or(media.where(teachable: related_courses))
         .or(media.where(teachable: Lesson.where(lecture: related_lectures)))
         .or(media.where(teachable: Talk.where(lecture: related_lectures)))
  end

  # returns array of all those sections from the given sections that belon to
  # the user's subscribed lectures
  def filter_sections(sections)
    sections.includes(:chapter).select { |s| s.lecture&.in?(related_lectures) }
  end

  # array of the user's subscribed lectures sorted by date
  def lectures_by_date
    lectures.sort
  end

  # array of the lectures the user has given as a teacher sorted by date
  def given_lectures_by_date
    given_lectures.sort
  end

  # array of all tags related to the users subscribed lectures
  def lecture_tags
    lectures.map(&:tags).flatten.uniq
  end

  def visible_tags(overrule_subscription_type: false)
    related_courses(overrule_subscription_type: overrule_subscription_type)
      .map(&:lectures).flatten.map(&:tags).flatten.uniq
  end

  # returns the array of those notifications of the user that are announcements
  # in the given lecture
  def active_notifications(lecture)
    notifications.where(notifiable: lecture.announcements)
                 .includes(notifiable: :announcer)
                 .sort_by { |n| n.notifiable.created_at }
                 .reverse
  end

  def active_media_notifications(lecture)
    notifications.where(notifiable_type: "Medium")
                 .where(notifiable_id: lecture.media_with_inheritance
                                              .pluck(:id))
  end

  # returns the array of those notifications that are related to MaMpf news
  # (i.e. announcements without a lecture)
  def active_news
    notifications.where(notifiable_type: "Announcement")
                 .select { |n| n.notifiable.lecture.nil? }
  end

  # returns the unique user notification that corresponds to the given
  # announcement
  def matching_notification(announcement)
    notifications.find_by(notifiable: announcement)
  end

  # a user is a teacher iff he/she has given any lecture
  def teacher?
    given_lectures.any?
  end

  # a user is a teachable editor iff he/she is a course editor or lecture
  # editor
  def teachable_editor?
    edited_courses.any? || edited_lectures.any?
  end

  def teachable_editor_or_teacher?
    teachable_editor? || teacher?
  end

  def can_edit_teachables?
    admin? || teachable_editor_or_teacher?
  end

  # if you are not a teacher of lecture or a module editor,
  # but just an additional editor of some lecture, you
  # will not be considered active if all of your edited lectures
  # are too old
  def active_teachable_editor?
    return false unless can_edit_teachables?
    return true if admin || course_editor? || teacher?

    edited_lectures.any? { |l| l.term.nil? || !l.stale? }
  end

  # a user is an editor iff he/she is a teachable editor or an
  # editor of media that are not associated to talks
  def editor?
    teachable_editor? ||
      edited_media.where.not(teachable_type: "Talk").any?
  end

  # the next methods return information about the user extracted from
  # email and name

  def info_uncached
    return email if name.blank?

    "#{name_in_tutorials.presence || name} (#{email})"
  end

  def info
    Rails.cache.fetch("#{cache_key_with_version}/user_info") do
      info_uncached
    end
  end

  def tutorial_info_uncached
    return email if tutorial_name.blank?

    "#{tutorial_name} (#{email})"
  end

  def tutorial_info
    Rails.cache.fetch("#{cache_key_with_version}/user_info") do
      tutorial_info_uncached
    end
  end

  def name_or_email
    return name if name.present?

    email
  end

  def tutorial_name
    full_name || name_in_tutorials.presence || name
  end

  def full_name
    [first_name, last_name].compact_blank.join(" ").presence
  end

  def personal_data_pending?
    personal_data_confirmed_at.nil? && personal_data_declined_at.nil?
  end

  def personal_data_declined?
    personal_data_declined_at.present? && personal_data_confirmed_at.nil?
  end

  def open_personal_data_fields
    LOCKED_PERSONAL_DATA_FIELDS.select { |field| attribute_in_database(field).blank? } +
      [:program_id, :uni_id]
  end

  def locked_personal_data_changed?
    LOCKED_PERSONAL_DATA_FIELDS.any? { |field| attribute_changed?(field) }
  end

  def short_info
    return email if name.blank?

    name
  end

  # editable courses are
  # - all courses if the user is an admin
  # - all edited courses otherwise
  def editable_courses
    return Course.all if admin

    edited_courses
  end

  # edited courses with inheritance are all edited courses together with the
  # courses that are parent of the edited lectures
  def edited_courses_with_inheritance
    (edited_courses + edited_lectures.map(&:course)).uniq
  end

  # edited or given courses with inheritance are all edited courses, together
  # with all courses that are parent of edited lectures or given lectures as
  # a teacher
  def edited_or_given_courses_with_inheritance
    (edited_courses + edited_lectures.map(&:course) +
      given_lectures.map(&:course)).uniq
  end

  # editable courses with inheritance are all editable courses (see above)
  # together with all courses that are parent to edite lectures
  def editable_courses_with_inheritance
    (editable_courses.includes(lectures: [:term, :teacher]) +
       edited_lectures.map(&:course)).uniq
  end

  # lectures as module editor are all lectures that belong to an edited course
  # but are neither edited lectures nor given lectures
  def lectures_as_course_editor
    Lecture.where(course: edited_courses) - edited_lectures.to_a -
      given_lectures.to_a
  end

  # teaching related lectures are given lectures, edited lectures and
  # lectures as module editor (see above)
  def teaching_related_lectures
    (given_lectures + edited_lectures + lectures_as_course_editor).uniq
  end

  def proper_teaching_related_lectures
    (given_lectures + edited_lectures).uniq
  end

  # teaching unrelated lectures are all lectures that are not teaching related
  def teaching_unrelated_lectures
    Lecture.includes(:term, :teacher, :course).all - teaching_related_lectures
  end

  def unrelated_courses
    Course.includes(:editors).all - edited_courses
  end

  # defines which messageboards a user can read:
  # - all boards if the user is an admin
  # - all boards that belong to teaching related lectures (see above)
  #   together with all boards belonging to unlocked lectures (see
  #   `unlocked_lectures`) if the user is course or lecture editor or teacher
  #   and all boards not belonging to lectures
  # - all boards that belong to unlocked lectures otherwise and all
  #    boards not belonging to lectures
  def thredded_can_read_messageboards
    return Thredded::Messageboard.all if admin?

    unlocked_forums =
      Thredded::Messageboard.where(id: unlocked_lectures.pluck(:forum_id))
                            .or(Thredded::Messageboard.where.not(id: Lecture.all.map(&:forum_id)))
    if teacher? || edited_courses.any? || edited_lectures.any?
      return Thredded::Messageboard.where(id: teaching_related_lectures
                                                  .map(&:forum_id))
                                   .or(unlocked_forums)
    end
    unlocked_forums
  end

  # defines which messageboards a user can write to:
  # - all those that he/she can read except those that do not belong to a
  #   lecture (they are for admins posts only)
  def thredded_can_write_messageboards
    return Thredded::Messageboard.all if admin?

    unlocked_forums =
      Thredded::Messageboard.where(id: unlocked_lectures.pluck(:forum_id))
    if teacher? || edited_courses.any? || edited_lectures.any?
      return Thredded::Messageboard.where(id: teaching_related_lectures
                                                  .map(&:forum_id))
                                   .or(unlocked_forums)
    end
    unlocked_forums
  end

  # defines which messageboards a user can moderate:
  # - all boards if the user is an admin
  # - all boards that belong to teaching related lectures (see above)
  #   if the user is course or lecture editor or teacher
  # - none otherwise
  def thredded_can_moderate_messageboards
    return Thredded::Messageboard.all if admin?

    if teacher? || edited_courses.any? || edited_lectures.any?
      return Thredded::Messageboard.where(id: teaching_related_lectures
                                                .map(&:forum_id))
    end
    Thredded::Messageboard.none
  end

  # for a given arel of media, returns those media that are visible for
  # the user
  # note: this concerns only access rights, not whether these media
  # match subscriptions or not
  # this method is more efficient than
  # media.select { |m| m.visible_for_user?(self)}
  def filter_visible_media(media)
    return media if admin

    # The same rule as Medium#visible_for_user?: "all" and "users" media are
    # everybody's, "subscribers" media ("only participants") need the user in
    # the audience of the lecture, or of one of the course's lectures.
    participating = LectureAudience.lectures_of(self)
    visible = media.where(released: ["all", "users"])
    [participating, Lesson.where(lecture: participating), Talk.where(lecture: participating),
     Course.where(id: participating.select(:course_id))].each do |teachables|
      visible = visible.or(media.where(teachable: teachables, released: "subscribers"))
    end
    visible.or(media.where(teachable: edited_courses))
           .or(media.where(teachable: teaching_related_lectures))
           .or(media.where(teachable: Lesson.where(lecture: teaching_related_lectures)))
           .or(media.where(teachable: Talk.where(lecture: teaching_related_lectures)))
  end

  # The commented media whose notices reach this user (see LectureAudience,
  # as in Commontator::CommentsController#update_unread_status), so the
  # comments page shows every thread the unread flag was raised for.
  def subscribed_commentable_media_with_comments
    audience = LectureAudience.lectures_of(self)
    media = Medium.where.not(sort: ["RandomQuiz", "Question", "Remark"])
    commentable = media.where(teachable: audience)
                       .or(media.where(teachable: Course.where(id: audience.select(:course_id))))
                       .or(media.where(teachable: Lesson.where(lecture: audience)))
                       .or(media.where(teachable: Talk.where(lecture: audience)))
    filter_visible_media(commentable).includes(commontator_thread: :comments)
                                     .select { |m| m.commontator_thread&.comments&.any? }
  end

  # Returns the media that the user has subscribed to and that have been
  # commented on by somebody else (not by the current user). The order is
  # given by the time of the latest comment by somebody else.
  #
  # Media that have not been commented on by somebody else than the current user,
  # are not returned (!).
  #
  # For each medium, the following information is stored:
  # - the medium itself
  # - the thread of the medium
  # - the latest comment by somebody else than the current user
  # - the latest comment by any user (which might include the current user)
  def subscribed_media_with_latest_comments_not_by_creator
    media = []

    subscribed_commentable_media_with_comments.each do |m|
      thread = m.commontator_thread
      comments = thread.comments
      next if comments.blank?

      comments_not_by_creator = comments.reject { |c| c.creator == self }
      next if comments_not_by_creator.blank?

      latest_comment = comments_not_by_creator.max_by(&:created_at)
      latest_comment_by_any_user = comments.max_by(&:created_at)

      media << { medium: m,
                 thread: thread,
                 latest_comment: latest_comment,
                 latest_comment_by_any_user: latest_comment_by_any_user }
    end

    media.sort_by { |x| x[:latest_comment].created_at }.reverse
  end

  # lecture that are in the active term
  # Teachers and editors see their lectures on the start page without
  # subscribing. As with the subscriptions, the current fold takes the
  # lectures without a term along.
  def current_staff_lectures
    staff_lectures_in([Term.active, nil])
  end

  def next_term_staff_lectures
    coming = Term.active&.next
    return [] if coming.blank?

    staff_lectures_in(coming)
  end

  def staff_lecture?(lecture)
    lecture.teacher == self || edited_lectures.include?(lecture)
  end

  # The published lectures whose content this user gets to see as a student:
  # those without a passphrase, and those unlocked via a bookmark. Scope
  # counterpart of Lecture#unlocked_for? (staff access is not included).
  def unlocked_lectures
    Lecture.published.where(passphrase: [nil, ""])
           .or(Lecture.published.where(id: lecture_bookmarks.select(:lecture_id)))
  end

  # The one rule for bookmarking a lecture by hand, which is also how a lecture
  # behind a pass phrase is unlocked. Returns whether the lecture is bookmarked
  # afterwards.
  def unlock_lecture!(lecture, passphrase: nil)
    return false unless may_unlock_lecture?(lecture, passphrase: passphrase)

    bookmark_lecture!(lecture)
    true
  end

  # The check of unlock_lecture! without the bookmark, for a form that must
  # vet every lecture before it saves any of them.
  def may_unlock_lecture?(lecture, passphrase: nil)
    return false unless lecture.published? || admin || lecture.edited_by?(self)

    lecture.bookmarkable_by?(self) || lecture.passphrase_matches?(passphrase)
  end

  def bookmark_lecture!(lecture)
    return false unless lecture.is_a?(Lecture)

    lecture_bookmarks.create_or_find_by(lecture: lecture)
                     .previously_new_record?
  end

  def unbookmark_lecture!(lecture)
    return false unless lecture.is_a?(Lecture)
    return false unless lecture.in?(lectures)

    lecture_bookmarks.where(lecture: lecture).destroy_all
    favorite_lectures.delete(lecture)

    true
  end

  # Every lecture this user holds a place in: a seat on the lecture roster,
  # which every tutorial seat comes with, or a place in one of its cohorts
  # (cohorts with propagate_to_lecture: false do not create a lecture seat).
  def roster_lectures
    Lecture.where(id: lecture_memberships.select(:lecture_id))
           .or(Lecture.where(id: cohorts.where(context_type: "Lecture")
                                        .select(:context_id)))
  end

  # Lectures with a pending application, or a rejected one not yet dismissed
  # (see Registration::UserRegistration#dismiss!). A confirmed application
  # is normally already covered by `roster_lectures`; this catches it before
  # rostering happens, or if the campaign never rosters the user at all.
  def lectures_with_registration_application
    campaign_ids = user_registrations
                   .where(status: [:pending, :confirmed])
                   .or(user_registrations.rejected.not_dismissed)
                   .select(:registration_campaign_id)
    Lecture.where(
      id: Registration::Campaign.where(id: campaign_ids,
                                       campaignable_type: "Lecture")
                                .non_exam
                                .select(:campaignable_id)
    )
  end

  # The lectures this user holds a place in for the given term, or has an
  # open application for (see `lectures_with_registration_application`).
  # Sorted by Registration::StatusQuery.sort_priority (confirmed first,
  # rejected last), ties kept in `lectures_of_term`'s title order.
  def current_enrolled_lectures(term = Term.active)
    combined = roster_lectures.or(lectures_with_registration_application)
    enrolled = lectures_of_term(combined, term)
    statuses = Registration::StatusQuery.new(self, enrolled.map(&:id)).statuses

    enrolled.sort_by.with_index do |lecture, index|
      [Registration::StatusQuery.sort_priority(statuses[lecture.id]), index]
    end
  end

  # Bookmarked but not already listed in `current_enrolled_lectures`. Pass
  # `enrolled` when the caller already computed it, to avoid recomputing it.
  def current_bookmarked_lectures(term = Term.active,
                                  enrolled: current_enrolled_lectures(term))
    lectures_of_term(lectures, term) - enrolled
  end

  def submission_partners(lecture)
    lecture_submissions = Submission.where(assignment: lecture.assignments)
    own_submissions = UserSubmissionJoin.where(user: self,
                                               submission: lecture_submissions)
                                        .pluck(:submission_id)
    partner_ids = UserSubmissionJoin.where(submission: own_submissions)
                                    .pluck(:user_id)
    User.where(id: partner_ids - [id])
  end

  def recent_submission_partners(lecture)
    recent_submissions = Submission.where(assignment:
                                            lecture.current_assignments +
                                              lecture.previous_assignments)
    own_submissions = UserSubmissionJoin.where(user: self,
                                               submission: recent_submissions)
                                        .pluck(:submission_id)
    partner_ids = UserSubmissionJoin.where(submission: own_submissions)
                                    .pluck(:user_id)
    User.where(id: partner_ids - [id])
  end

  def rostered_tutorial_in(lecture)
    tutorial_membership = tutorial_memberships.joins(:tutorial)
                                              .find_by(tutorials: { lecture_id: lecture.id })
    tutorial_membership&.tutorial
  end

  def tutor?
    given_tutorials.any?
  end

  def tutor_in?(tutorial)
    given_tutorials.include?(tutorial)
  end

  def teacher_in?(lecture)
    given_lectures.include?(lecture)
  end

  def editor_or_teacher_in?(lecture)
    in?(lecture.editors) || self == lecture.teacher
  end

  def tutorials(lecture)
    given_tutorials.where(lecture: lecture)
  end

  def proper_submissions_count
    submissions.proper.size
  end

  def proper_single_submissions_count
    submissions.proper.count { |s| s.users.size == 1 }
  end

  def proper_team_submissions_count
    proper_submissions_count - proper_single_submissions_count
  end

  def media_editor?
    edited_media.any?
  end

  def contributor?
    teacher? || media_editor?
  end

  def archive_and_destroy(archive_name)
    if contributor?
      success = transfer_contributions_to(archive_user(archive_name))
      return false unless success
    end
    self.skip_destroy_talk_media = true
    destroy
  end

  def proper_student_in?(lecture)
    lecture.published? && lecture.unlocked_for?(self) &&
      !in?(lecture.tutors) && !in?(lecture.editors) && self != lecture.teacher
  end

  def original_image_file
    image
  end

  def normalized_image_file
    return unless image && image(:normalized)

    image(:normalized)
  end

  def image_filename
    return unless image

    image.metadata["filename"]
  end

  def image_size
    return unless image

    image.metadata["size"]
  end

  def image_resolution
    return unless image

    "#{image.metadata["width"]}x#{image.metadata["height"]}"
  end

  def can_edit?(something)
    unless something.is_a?(Lecture) || something.is_a?(Course) ||
           something.is_a?(Medium) || something.is_a?(Lesson) ||
           something.is_a?(Talk)
      raise("can_edit? was called with incompatible class")
    end
    return true if admin

    in?(something.editors_with_inheritance.to_a)
  end

  def can_enter_points_in?(something)
    unless something.is_a?(Lecture) || something.is_a?(Tutorial)
      raise(IncompatibleTypeError, "can_enter_points_in? was called with incompatible class")
    end
    return true if admin

    in?(something.graders_with_inheritance.to_a)
  end

  def can_enter_grades_in?(something)
    unless something.is_a?(Lecture)
      raise(IncompatibleTypeError, "can_enter_grades_in? was called with incompatible class")
    end
    return true if admin

    in?(something.graders_with_inheritance.to_a)
  end

  def speaker?
    talks.any?
  end

  def layout
    return "administration" if admin_or_editor?

    "application_no_sidebar"
  end

  def course_editor?
    edited_courses.any?
  end

  def admin_or_editor?
    admin? || editor?
  end

  def generic?
    !(admin? || teacher? || editor?)
  end

  # for lectures that are too old, only the teacher or an editor
  # of the course it belongs to can update the personell of to the lecture
  def can_update_personell?(lecture)
    return false unless can_edit?(lecture)
    return true if can_edit?(lecture.course) || lecture.teacher == self
    return true if lecture.course.term_independent
    return true unless lecture.stale?

    false
  end

  # see https://github.com/heartcombo/devise/issues/4849#issuecomment-534733131
  # We use the Devise::Trackable module to track sign-in count and current/last
  # sign-in timestamp. However, we don't want to track IP address, but Trackable
  # tries to, so we have to manually override the accessor methods so they do
  # nothing.

  def current_sign_in_ip
  end

  def last_sign_in_ip=(_ip)
  end

  def current_sign_in_ip=(_ip)
  end

  ##############################################################################
  # Annotations
  ##############################################################################

  def own_annotations
    Annotation.where(user: self)
  end

  def students_annotations
    Annotation.where(medium_id: medium_ids_of_lectures_or_edited_lectures,
                     visible_for_teacher: true)
  end

  private

    # Term-independent lectures belong to every term, so they follow the ones
    # of the selected term rather than being left out.
    def lectures_of_term(scope, term)
      independent = scope.where(term: nil).includes(:course, :teacher)
                         .natural_sort_by(&:title)
      return independent if term.nil?

      scope.where(term: term).includes(:course, :term, :teacher)
           .natural_sort_by(&:title) + independent
    end

    def program_offered_to_students
      return if program.nil? || program.degree.present?

      errors.add(:program_id, :inclusion)
    end

    def staff_lectures_in(terms)
      given = given_lectures.where(term: terms).includes(:course, :term)
      edited = edited_lectures.where(term: terms).includes(:course, :term, :teacher)
      (given + edited).uniq.natural_sort_by(&:title)
    end

    def password_differs_from_current
      stored = encrypted_password_in_database
      return if stored.blank?
      return unless Devise::Encryptor.compare(self.class, stored, password)

      errors.add(:password, I18n.t("errors.messages.password_unchanged"))
    end

    # Covers creation too: a new account writes its password like any change.
    def track_password_change
      return unless will_save_change_to_encrypted_password?

      self.password_policy_version = CURRENT_PASSWORD_POLICY_VERSION
      self.password_changed_at = Time.zone.now
    end

    def set_defaults
      self.subscription_type ||= 1
      self.admin ||= false
      self.name ||= email.split("@").first
      self.locale ||= I18n.default_locale.to_s
    end

    # sets time for DSGVO consent to current time
    def set_consented_at
      self.consented_at = Time.zone.now
    end

    # returns array of ids of all courses that preced the subscribed courses
    def preceding_course_ids
      courses.all.map { |l| l.preceding_courses.pluck(:id) }.flatten +
        courses.pluck(:id)
    end

    def destroy_single_submissions
      Submission.where(id: submissions.select { |s| s.users.one? }
                                      .map(&:id)).destroy_all
    end

    # Destroys all talk media of the user.
    # If the user is an editor of media other than talk-related media,
    # nothing will happen.
    def destroy_talk_media_upon_user_deletion
      return if edited_media.where.not(teachable_type: "Talk").any?

      # Only delete media where the user is the sole editor.
      sole_editor_media = edited_media.select { |m| m.editors.one? }
      Medium.where(id: sole_editor_media.pluck(:id)).destroy_all
    end

    def archive_email
      splitting = DefaultSetting::PROJECT_EMAIL.split("@")
      "#{splitting.first}-archive-#{id}@#{splitting.second}"
    end

    def transfer_contributions_to(user)
      return false unless user&.valid? && user != self

      given_lectures.update(teacher_id: user.id)
      EditableUserJoin.where(user: self, editable_type: "Medium")
                      .update(user_id: user.id)
    end

    # The archive account is never signed into, but its password still has to
    # pass the policy -- otherwise the record is invalid and no archive is
    # created.
    def archive_user(archive_name)
      User.create(name: archive_name,
                  email: archive_email,
                  password: SecureRandom.base58(Devise.password_length.min),
                  consents: true,
                  consented_at: Time.zone.now,
                  confirmed_at: Time.zone.now,
                  archived: true)
    end

    def medium_ids_of_lectures_or_edited_lectures
      lectures = given_lectures + edited_lectures
      lectures.flat_map(&:media_with_inheritance).pluck(:id)
    end
end

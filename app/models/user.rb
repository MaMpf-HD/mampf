# User class
class User < ApplicationRecord
  include ApplicationHelper

  # use devise for authentification, include the following modules
  devise :database_authenticatable, :registerable, :trackable,
         :recoverable, :rememberable, :validatable, :confirmable, :lockable

  # a user has many subscribed lectures
  has_many :lecture_user_joins, dependent: :destroy
  has_many :lectures, -> { distinct }, through: :lecture_user_joins

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

  # a user may have many user answers for questionnaires that they filled out.
  has_many :vignettes_user_answers, dependent: :destroy, class_name: "Vignettes::UserAnswer"

  # a user has a codename per vignettes lecture that is used as a pseudonym
  has_many :vignettes_codenames,
           dependent: :destroy,
           class_name: "Vignettes::Codename",
           inverse_of: :user

  # a user has a watchlist with watchlist_entries
  has_many :watchlists, dependent: :destroy

  has_many :feedbacks, dependent: :destroy

  # a user has redemptions of vouchers
  has_many :redemptions, dependent: :destroy

  include ScreenshotUploader[:image]

  # if a homepage is given it should at leat be a valid address
  validates :homepage, http_url: true, if: :homepage?

  validates :locale, inclusion: { in: I18n.available_locales.map(&:to_s) },
                     if: :locale?

  # a user needs to give a display name
  validates :name, presence: true, if: :persisted?

  # set some default values before saving if they are not set
  before_save :set_defaults

  # add timestamp for DSGVO consent
  after_create :set_consented_at
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

  # returns the array of all editors
  def self.editors
    User.where(id: EditableUserJoin.distinct.select(:user_id))
  end

  # returns the array of all editors minus those that are only editors of talks
  def self.proper_editors
    talk_media_ids = Medium.where(teachable_type: "Talk").pluck(:id)
    talk_media_joins = EditableUserJoin.where(editable_type: "Medium",
                                              editable_id: talk_media_ids)
    User.where(id: EditableUserJoin.where.not(id: talk_media_joins.pluck(:id))
                                   .pluck(:user_id).uniq)
  end

  # Returns the array of all editors (of courses, lectures, media), together
  # with their ids
  # Is used in options_for_select in form helpers.
  def self.only_editors_selection
    User.editors.map { |e| [e.info, e.id] }.natural_sort_by(&:first)
  end

  # returns the ARel of all users that are editors or whose id is among a
  # given array of ids
  # search params is a hash having keys :all_editors, :editor_ids
  def self.search_editors(search_params)
    return User.editors unless search_params[:all_editors] == "0"

    editor_ids = search_params[:editor_ids] || []
    User.where(id: editor_ids)
  end

  # array of all users together with their ids for use in options_for_select
  # (e.g. in a select editors form)
  def self.select_editors
    User.pluck(:name, :email, :id, :name_in_tutorials)
        .map { |u| ["#{u.fourth.presence || u.first} (#{u.second})", u.third] }
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
    name_in_tutorials.presence || name
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
  #   together with all boards belonging to subscribed lectures if the user
  #   is course or lecture editor or teacher and all boards not belonging
  #   to lectures
  # - all boards that belong to subscribed lectures otherwise and all
  #    boards not belonging to lectures
  def thredded_can_read_messageboards
    return Thredded::Messageboard.all if admin?

    subscribed_forums =
      Thredded::Messageboard.where(id: lectures.map(&:forum_id))
                            .or(Thredded::Messageboard.where.not(id: Lecture.all.map(&:forum_id)))
    if teacher? || edited_courses.any? || edited_lectures.any?
      return Thredded::Messageboard.where(id: teaching_related_lectures
                                                  .map(&:forum_id))
                                   .or(subscribed_forums)
    end
    subscribed_forums
  end

  # defines which messageboards a user can write to:
  # - all those that he/she can read except those that do not belong to a
  #   lecture (they are for admins posts only)
  def thredded_can_write_messageboards
    return Thredded::Messageboard.all if admin?

    subscribed_forums =
      Thredded::Messageboard.where(id: lectures.map(&:forum_id))
    if teacher? || edited_courses.any? || edited_lectures.any?
      return Thredded::Messageboard.where(id: teaching_related_lectures
                                                  .map(&:forum_id))
                                   .or(subscribed_forums)
    end
    subscribed_forums
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
    nonsubscribed_courses =
      Course.where(id: Course.pluck(:id) - courses.pluck(:id))
    nonsubscribed_lectures =
      Lecture.where(id: Lecture.pluck(:id) - lectures.pluck(:id),
                    released: ["all"])
    lessons = Lesson.where(lecture: lectures)
    nonsubscribed_lessons = Lesson.where(lecture: nonsubscribed_lectures)
    edited_lessons = Lesson.where(lecture: teaching_related_lectures)
    talks = Talk.where(lecture: lectures)
    nonsubscribed_talks = Talk.where(lecture: nonsubscribed_lectures)
    edited_talks = Talk.where(lecture: teaching_related_lectures)
    return media if admin

    media.where(teachable: courses, released: ["all", "subscribers", "users"])
         .or(media.where(teachable: nonsubscribed_courses,
                         released: ["all", "users"]))
         .or(media.where(teachable: lectures,
                         released: ["all", "subscribers", "users"]))
         .or(media.where(teachable: nonsubscribed_lectures,
                         released: ["all", "users"]))
         .or(media.where(teachable: lessons,
                         released: ["all", "subscribers", "users"]))
         .or(media.where(teachable: nonsubscribed_lessons,
                         released: ["all", "users"]))
         .or(media.where(teachable: talks,
                         released: ["all", "subscribers", "users"]))
         .or(media.where(teachable: nonsubscribed_talks,
                         released: ["all", "users"]))
         .or(media.where(teachable: edited_courses))
         .or(media.where(teachable: teaching_related_lectures))
         .or(media.where(teachable: edited_lessons))
         .or(media.where(teachable: edited_talks))
  end

  def subscribed_commentable_media_with_comments
    lessons = Lesson.where(lecture: lectures)
    filter_media(Medium.where.not(sort: ["RandomQuiz", "Question", "Erdbeere",
                                         "Remark"])
                       .where(teachable: courses + lectures + lessons))
      .includes(commontator_thread: :comments)
      .select { |m| m.commontator_thread.comments.any? }
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
  def active_lectures
    lectures.where(term: Term.active).includes(:course, :term)
  end

  def inactive_lectures
    lectures.where.not(term: Term.active)
  end

  def nonsubscribed_lectures
    Lecture.where.not(id: lectures.pluck(:id))
  end

  def anonymized_id
    Digest::SHA2.hexdigest(id.to_s + created_at.to_s).first(20)
  end

  def subscribe_lecture!(lecture)
    return false unless lecture.is_a?(Lecture)
    return false if lecture.in?(lectures)

    lectures << lecture

    # make sure subscribed_users is updated in media
    Sunspot.index!(lecture.media)

    true
  end

  def unsubscribe_lecture!(lecture)
    return false unless lecture.is_a?(Lecture)
    return false unless lecture.in?(lectures)

    lectures.delete(lecture)
    favorite_lectures.delete(lecture)

    # make sure subscribed_users is updated in media
    Sunspot.index!(lecture.media)
    true
  end

  def current_subscribed_lectures
    active_lectures.includes(:course, :term).natural_sort_by(&:title) +
      lectures.where(term: nil).natural_sort_by(&:title)
  end

  def current_subscribable_lectures
    current_lectures = Lecture.in_current_term.where.not(sort: "vignettes").includes(:course, :term)
    no_term_lectures = Lecture.no_term.where.not(sort: "vignettes").includes(:course, :term)
    return current_lectures.sort + no_term_lectures.sort if admin
    unless editor? || teacher?
      return current_lectures.published.sort + no_term_lectures.published.sort
    end

    current_lectures.select { |l| l.edited_by?(self) || l.published? }.sort +
      no_term_lectures.select { |l| l.edited_by?(self) || l.published? }.sort
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

  def tutor?
    given_tutorials.any?
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
    lecture.in?(lectures) && !in?(lecture.tutors) && !in?(lecture.editors) &&
      self != lecture.teacher
  end

  def image_url_with_host
    return unless image

    image_url(host: host)
  end

  def normalized_image_url_with_host
    return unless image && image(:normalized)

    image_url(:normalized, host: host)
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

    def set_defaults
      self.subscription_type ||= 1
      self.admin ||= false
      self.name ||= email.split("@").first
      self.locale ||= I18n.default_locale.to_s
    end

    # sets time for DSGVO consent to current time
    def set_consented_at
      update(consented_at: Time.zone.now)
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

    def archive_user(archive_name)
      User.create(name: archive_name,
                  email: archive_email,
                  password: SecureRandom.base58(12),
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

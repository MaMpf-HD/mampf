# User class
class User < ApplicationRecord
  # use devise for authentification, include the following modules
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # a user has many subscribed lectures
  has_many :lecture_user_joins, dependent: :destroy
  has_many :lectures, through: :lecture_user_joins

  # a user has many subscribed courses
  has_many :course_user_joins, dependent: :destroy
  has_many :courses, through: :course_user_joins

  # a user has many courses as an editor
  has_many :editable_user_joins, foreign_key: :user_id, dependent: :destroy
  has_many :edited_courses, through: :editable_user_joins,
                            source: :editable, source_type: 'Course'

  # a user has many lectures as an editor
  has_many :edited_lectures, through: :editable_user_joins,
                             source: :editable, source_type: 'Lecture'

  # a user has many media as an editor
  has_many :edited_media, through: :editable_user_joins,
                          source: :editable, source_type: 'Medium'

  # a user has many lectures as a teacher
  has_many :given_lectures, class_name: 'Lecture', foreign_key: 'teacher_id'

  # a user has many notifications as recipient
  has_many :notifications, foreign_key: 'recipient_id'

  # a user has many announcements as announcer
  has_many :announcements, foreign_key: 'announcer_id'

  # at least one course must be subscribed (if there are courses)
  validates :courses,
            presence: { message: 'Es muss mindestens ein Modul abonniert ' \
                                 'werden.' },
            if: :courses_exist?

  # if a homepage is given it should at leat be a valid address
  validates :homepage, http_url: true, if: :homepage?

  # a user needs to give a display name
  validates :name,
            presence: { message: 'Es muss ein Anzeigename angegeben werden.' },
            if: :edited_profile?

  # set some default values before saving if they are not set
  before_save :set_defaults

  # add timestamp for DSGVO consent
  after_create :set_consented_at

  # array of all users together with their ids for use in options_for_select
  # (e.g. in a select editors form)
  def self.select_editors
    User.all.map { |u| [u.info, u.id] }
  end

  # array of hashes of user ids together with user info
  def self.select_editors_hash
    User.all.map { |u| { text: u.info, value: u.id } }
  end

  # returns the array of all teachers
  def self.teachers
    User.includes(:given_lectures).select(&:teacher?)
  end

  # returns the array of all editors
  def self.editors
    User.includes(:edited_courses, :edited_lectures, :edited_media)
        .select(&:editor?)
  end

  # Returns the array of all editors (of courses, lectures, media), together
  # with their ids
  # Is used in options_for_select in form helpers.
  def self.only_editors_selection
    User.editors.map { |e| [e.info, e.id] }
  end

  # returns the ARel of all users that are editors or whose id is among a
  # given array of ids
  # search params is a hash having keys :all_editors, :editor_ids
  def self.search_editors(search_params)
    return User.editors unless search_params[:all_editors] == '0'
    editor_ids = search_params[:editor_ids] || []
    User.where(id: editor_ids)
  end

  # related courses for user are
  # - all courses that the user has subscribe to plus their preceding courses
  #   (if subscription type is 1)
  # - all courses (if subscription type is 2)
  # - all courses that the user has subscribed to (if subscription type is 3)
  def related_courses
    return if subscription_type.nil?
    if subscription_type == 1
      return Course.where(id: preceding_course_ids).includes(:lectures)
    end
    return Course.all.includes(:lectures) if subscription_type == 2
    courses
  end

  # array of all administrated courses together with their ids
  # administrated courses are:
  # - all courses if the user is an admin,
  # - all courses edited by the user otherwise
  def select_administrated_courses
    relevant = admin ? Course.all : edited_courses
    relevant.map { |c| [c.title, c.id] }
  end

  # related lectures are lectures associated to related courses (see above)
  def related_lectures
    related_courses.map(&:lectures).flatten
  end

  # returns ARel of all those tags from the given tags that belong to
  # the user's related lectures
  def filter_tags(tags)
    Tag.where(id: tags.select { |t| t.in_lectures?(related_lectures) }
                      .map(&:id))
  end

  # returns ARel of all those lectures from the given lectures that belong to
  # the user's related lectures
  def filter_lectures(lectures)
    Lecture.where(id: lectures.pluck(:id) & related_lectures.pluck(:id))
  end

  #  # returns ARel of all those media from the given media that are related to
  # the user's related lectures
  def filter_media(media)
    Medium
      .where(id: media.select { |m| m.related_to_lectures?(related_lectures) }
                      .map(&:id))
  end

  # returns array of all those sections from the given sections that belon to
  # the user's subscribed lectures
  def filter_sections(sections)
    sections.includes(:chapter).select { |s| s.lecture&.id&.in?(lecture_ids) }
  end

  # array of the user's subscribed lectures sorted by date
  def lectures_by_date
    lectures.to_a.sort do |i, j|
      j.term.begin_date <=> i.term.begin_date
    end
  end

  # array of the lectures the user has given as a teacher sorted by date
  def given_lectures_by_date
    given_lectures.to_a.sort do |i, j|
      j.term.begin_date <=> i.term.begin_date
    end
  end

  # array of all tags related to the users subscribed lectures
  def lecture_tags
    lectures.map(&:tags).flatten.uniq
  end

  # returns the array of those notifications of the user that are announcements
  # in the given lecture
  def active_announcements(lecture)
    notifications.where(notifiable_type: 'Announcement')
                 .select { |n| n.notifiable.lecture == lecture }
  end

  # returns the array of those notifications that are related to MaMpf news
  # (i.e. announcements without a lecture)
  def active_news
    active_announcements(nil)
  end

  # returns the unique user notification that corresponds to the given
  # announcement
  def matching_notification(announcement)
    notifications.where(notifiable_type: 'Announcement',
                        notifiable_id: announcement.id)&.first
  end

  # a user is a teacher iff he/she has given any lecture
  def teacher?
    given_lectures.any?
  end

  # a user is an editor iff he/she is a course editro od lecture editor or
  # media editor
  def editor?
    edited_courses.any? || edited_lectures.any? || edited_media.any?
  end

  # the next three methods return information about the user extracted from
  # email and name

  def info
    return email unless name.present?
    name + ' (' + email + ')'
  end

  def name_or_email
    return name unless name.blank?
    email
  end

  def short_info
    return email unless name.present?
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
    (editable_courses + edited_lectures.map(&:course)).uniq
  end

  # lectures as module editor are all lectures that belong to an edited course
  # but are neither edited lectures nor given lectures
  def lectures_as_module_editor
    edited_courses.map(&:lectures).flatten - edited_lectures.to_a -
      given_lectures.to_a
  end

  # teaching related lectures are given lectures, edited lectures and
  # lectures as module editor (see above)
  def teaching_related_lectures
    (given_lectures + edited_lectures + lectures_as_module_editor).uniq
  end

  # teaching unrelated lectures are all lectures that are not teaching related
  def teaching_unrelated_lectures
    Lecture.all - teaching_related_lectures
  end

  # defines which messageboards a user can read:
  # - all boards if the user is an admin
  # - all boards that belong to teaching related lectures (see above)
  #   together with all boards belonging to subscribed lectures if the user
  #   is course or lecture editor or teacher
  # - all boards that belong to subscribed lectures otherwise
  def thredded_can_read_messageboards
    return Thredded::Messageboard.all if admin?
    subscribed_forums =
      Thredded::Messageboard.where(name: lectures.map(&:title))
    if teacher? || edited_courses.any? || edited_lectures.any?
      return Thredded::Messageboard.where(name: teaching_related_lectures
                                                  .map(&:title))
                                   .or(subscribed_forums)
    end
    subscribed_forums
  end

  # defines which messageboards a user can write to:
  # - all those that he/she can read
  def thredded_can_write_messageboards
    thredded_can_read_messageboards
  end

  # defines which messageboards a user can moderate:
  # - all boards if the user is an admin
  # - all boards that belong to teaching related lectures (see above)
  #   if the user is course or lecture editor or teacher
  # - none otherwise
  def thredded_can_moderate_messageboards
    return Thredded::Messageboard.all if admin?
    if teacher? || edited_courses.any? || edited_lectures.any?
      return Thredded::Messageboard.where(name: teaching_related_lectures
                                                  .map(&:title))
    end
    Thredded::Messageboard.none
  end

  private

  def set_defaults
    self.subscription_type = 1 if subscription_type.nil?
    self.admin = false if admin.nil?
  end

  # sets time for DSGVO consent to current time
  def set_consented_at
    update(consented_at: Time.now)
  end

  def courses_exist?
    return true if Course.all.any? && edited_profile?
  end

  # returns array of ids of all courses that preced the subscribed courses
  def preceding_course_ids
    courses.all.map { |l| l.preceding_courses.pluck(:id) }.flatten +
      courses.all.pluck(:id)
  end

  def admin_or_editor?
    return true if admin? || editor?
    false
  end
end

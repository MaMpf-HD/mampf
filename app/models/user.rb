# User class
class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :lecture_user_joins, dependent: :destroy
  has_many :lectures, through: :lecture_user_joins
  has_many :course_user_joins, dependent: :destroy
  has_many :courses, through: :course_user_joins
  has_many :editable_user_joins, foreign_key: :user_id, dependent: :destroy
  has_many :edited_courses, through: :editable_user_joins,
                            source: :editable, source_type: 'Course'
  has_many :edited_lectures, through: :editable_user_joins,
                             source: :editable, source_type: 'Lecture'
  has_many :edited_media, through: :editable_user_joins,
                          source: :editable, source_type: 'Medium'
  has_many :given_lectures, class_name: 'Lecture', foreign_key: 'teacher_id'
  has_many :notifications, foreign_key: 'recipient_id'
  has_many :announcements, foreign_key: 'announcer_id'
  validates :courses,
            presence: { message: 'Es muss mindestens ein Modul abonniert ' \
                                 'werden.' },
            if: :courses_exist?
  validates :homepage, http_url: true, if: :homepage?
  validates :name,
            presence: { message: 'Es muss ein Anzeigename angegeben werden.' },
            if: :edited_profile?
  before_save :set_defaults
  after_create :set_consented_at

  def self.select_editors
    User.all.map { |u| [u.info, u.id] }
  end

  def self.select_editors_hash
    User.all.map { |u| { text: u.info, value: u.id } }
  end

  def self.teachers
    User.includes(:given_lectures).select(&:teacher?)
  end

  def self.editors
    User.includes(:edited_courses,:edited_lectures, :edited_media)
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

  def related_courses
    return if subscription_type.nil?
    return Course.where(id: preceding_course_ids).includes(:lectures) if subscription_type == 1
    return Course.all.includes(:lectures) if subscription_type == 2
    courses
  end

  def select_administrated_courses
    relevant = admin ? Course.all : edited_courses
    relevant.map { |c| [c.title, c.id] }
  end

  def related_lectures
    related_courses.map(&:lectures).flatten
  end

  def filter_tags(tags)
    Tag.where(id: tags.select { |t| t.in_lectures?(related_lectures) }
                      .map(&:id))
  end

  def filter_lectures(lectures)
    Lecture.where(id: lectures.pluck(:id) & related_lectures.pluck(:id))
  end

  def filter_media(media)
    Medium
      .where(id: media.select { |m| m.related_to_lectures?(related_lectures) }
                      .map(&:id))
  end

  def lectures_by_date
    lectures.to_a.sort do |i, j|
      j.term.begin_date <=> i.term.begin_date
    end
  end

  def given_lectures_by_date
    given_lectures.to_a.sort do |i, j|
      j.term.begin_date <=> i.term.begin_date
    end
  end

  def lecture_tags
    lectures.map(&:tags).flatten.uniq
  end

  def active_announcements(lecture)
    notifications.where(notifiable_type: 'Announcement')
                 .select { |n| n.notifiable.lecture == lecture }
  end

  def active_news
    active_announcements(nil)
  end

  def matching_notification(announcement)
    notifications.where(notifiable_type: 'Announcement',
                        notifiable_id: announcement.id)&.first
  end

  def teacher?
    given_lectures.any?
  end

  def editor?
    edited_courses.any? || edited_lectures.any? || edited_media.any?
  end

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

  def editable_courses
    return Course.all if admin
    edited_courses
  end

  def edited_courses_with_inheritance
    (edited_courses + edited_lectures.map(&:course)).uniq
  end

  def editable_courses_with_inheritance
    (editable_courses + edited_lectures.map(&:course)).uniq
  end

  def lectures_as_module_editor
    edited_courses.map(&:lectures).flatten - edited_lectures.to_a - given_lectures.to_a
  end

  def teaching_related_lectures
    (given_lectures + edited_lectures + lectures_as_module_editor).uniq
  end

  def teaching_unrelated_lectures
    Lecture.all - teaching_related_lectures
  end

  def thredded_can_read_messageboards
    return Thredded::Messageboard.all if admin?
    subscribed_forums = Thredded::Messageboard.where(name: lectures.map(&:title))
    if teacher? || edited_courses.any? || edited_lectures.any?
      return Thredded::Messageboard.where(name: teaching_related_lectures
                                                  .map(&:title))
                                   .or(subscribed_forums)
    end
    subscribed_forums
  end

  def thredded_can_write_messageboards
    thredded_can_read_messageboards
  end

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

  def set_consented_at
    update(consented_at: Time.now)
  end

  def courses_exist?
    return true if Course.all.present? && edited_profile?
  end

  def preceding_course_ids
    courses.all.map { |l| l.preceding_courses.pluck(:id) }.flatten +
      courses.all.pluck(:id)
  end

  def admin_or_editor?
    return true if admin? || editor?
    false
  end
end

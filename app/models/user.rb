# User class
class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :lecture_user_joins, dependent: :destroy
  has_many :lectures, through: :lecture_user_joins
  has_many :course_user_joins, dependent: :destroy
  has_many :courses, through: :course_user_joins
  has_many :editable_user_joins, foreign_key: :user_id
  has_many :edited_courses, through: :editable_user_joins,
           source: :editable, source_type: 'Course'
  has_many :edited_lectures, through: :editable_user_joins,
           source: :editable, source_type: 'Lecture'
  has_many :edited_lessons, through: :editable_user_joins,
           source: :editable, source_type: 'Lesson'
  has_many :edited_media, through: :editable_user_joins,
           source: :editable, source_type: 'Medium'
  belongs_to :teacher, optional: true
  validates :courses,
            presence: { message: 'Es muss mindestens ein Modul abonniert ' \
                                 'werden.' },
            if: :courses_exist?
  before_save :set_defaults
  after_create :set_consented_at

  def self.select_editors
    User.where(editor: true).all.map { |c| [c.email, c.id] }
  end

  def related_courses
    return if subscription_type.nil?
    return Course.where(id: preceding_course_ids) if subscription_type == 1
    return Course.all if subscription_type == 2
    courses
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

  def project?(course, project)
    return false if course.nil?
    return false unless course.public_send(project + '?')
    join = CourseUserJoin.where(course: course, user: self)
    return false if join.empty?
    return false if join.first.public_send(project + '?') == false
    true
  end

  def sesam?(course)
    project?(course, 'sesam')
  end

  def kiwi?(course)
    project?(course, 'kiwi')
  end

  def reste?(course)
    project?(course, 'reste')
  end

  def keks?(course)
    project?(course, 'keks')
  end

  def erdbeere?(course)
    project?(course, 'erdbeere')
  end

  private

  def set_defaults
    self.subscription_type = 1 if subscription_type.nil?
    self.admin = false if admin.nil?
    self.teacher = false if teacher.nil?
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
end

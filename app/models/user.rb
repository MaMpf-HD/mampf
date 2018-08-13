# User class
class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :lecture_user_joins, dependent: :destroy
  has_many :lectures, through: :lecture_user_joins
  has_many :course_user_joins, dependent: :destroy
  has_many :courses, through: :course_user_joins
  validates :courses,
            presence: { message: 'Es muss mindestens ein Modul abonniert ' \
                                 'werden.' },
            if: :courses_exist?
  before_save :set_defaults
  after_create :set_consented_at

  def related_courses
    return if subscription_type.nil?
    case subscription_type
    when 1
      ids = courses.all.map { |l| l.preceding_courses.pluck(:id) }.flatten +
                                  courses.all.pluck(:id)
      return Course.where(id: ids)
    when 2
      return Course.all
    when 3
      return courses
    end
  end

  def related_lectures
    related_courses.map { |c| c.lectures }.flatten
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

  def sesam?(course)
    return false if course.nil?
    return false unless course.sesam?
    join = CourseUserJoin.where(course: course, user: self)
    return false if join.empty?
    return false if join.first.sesam? == false
    true
  end

  def kiwi?(course)
    return false if course.nil?
    return false unless course.kiwi?
    join = CourseUserJoin.where(course: course, user: self)
    return false if join.empty?
    return false if join.first.kiwi? == false
    true
  end

  def reste?(course)
    return false if course.nil?
    return false unless course.reste?
    join = CourseUserJoin.where(course: course, user: self)
    return false if join.empty?
    return false if join.first.reste? == false
    true
  end

  def keks?(course)
    return false if course.nil?
    return false unless course.keks?
    join = CourseUserJoin.where(course: course, user: self)
    return false if join.empty?
    return false if join.first.keks? == false
    true
  end

  def erdbeere?(course)
    return false if course.nil?
    return false unless course.erdbeere?
    join = CourseUserJoin.where(course: course, user: self)
    return false if join.empty?
    return false if join.first.erdbeere? == false
    true
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
end

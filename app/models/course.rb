# Course class
class Course < ApplicationRecord
  has_many :lectures, dependent: :destroy
  has_many :course_tag_joins
  has_many :tags, through: :course_tag_joins
  has_many :media, as: :teachable
  has_many :course_user_joins, dependent: :destroy
  has_many :users, through: :course_user_joins
  has_many :course_self_joins, dependent: :destroy
  has_many :preceding_courses, through: :course_self_joins
  validates :title, presence: true, uniqueness: true
  validates :short_title, presence: true, uniqueness: true

  def to_label
    title
  end

  def description
    { general: title }
  end

  def kaviar?
    project?('kaviar')
  end

  def sesam?
    project?('sesam')
  end

  def keks?
    project?('keks')
  end

  def erdbeere?
    project?('erdbeere')
  end

  def kiwi?
    project?('kiwi')
  end

  def reste?
    project?('reste')
  end

  def available_extras
    hash = { 'news' => news.present?, 'sesam' => sesam?, 'keks' => keks?,
             'erdbeere' => erdbeere?, 'kiwi' => kiwi?, 'reste' => reste? }
    hash.keys.select { |k| hash[k] == true }
  end

  def available_food
    kaviar_info = kaviar? ? ['kaviar'] : []
    kaviar_info.concat(available_extras)
  end

  def lectures_by_date
    lectures.to_a.sort do |i, j|
      j.term.begin_date <=> i.term.begin_date
    end
  end

  def news_for_user?(user)
    return false unless news.present?
    return false unless user.courses.include?(self)
    if CourseUserJoin.where(course: self, user: user).first.news? == false
      return false
    end
    true
  end

  def extras(user_params)
    extra_modules = extract_extra_modules(user_params)
    modules = {}
    available_extras.each { |e| modules[e + '?'] = false }
    extra_modules.each { |e| modules[e] = true }
    primary_id = user_params['primary_lecture-' + id.to_s]
    modules['primary_lecture_id'] = primary_id == '0' ? nil : primary_id.to_i
    modules
  end

  def course
    self
  end

  def lecture
  end

  def lesson
  end

  def front_lecture(user, active_lecture_id)
    if subscribed_lectures(user).map(&:id).include?(active_lecture_id)
      return Lecture.find(active_lecture_id)
    end
    primary_lecture(user)
  end

  def primary_lecture(user)
    user_join = CourseUserJoin.where(course: self, user: user)
    return if user_join.empty?
    Lecture.find_by_id(user_join.first.primary_lecture_id)
  end

  def subscribed_lectures(user)
    course.lectures & user.lectures
  end

  def subscribed_lectures_by_date(user)
    subscribed_lectures(user).to_a.sort do |i, j|
      j.term.begin_date <=> i.term.begin_date
    end
  end

  def subscribed_by?(user)
    user.courses.include?(self)
  end

  private

  def filter_keys(user_params)
    user_params.keys.select do |k|
      k.end_with?('-' + id.to_s) && !k.include?('lecture-') &&
        !k.start_with?('course-') && user_params[k] == '1'
    end
  end

  def extract_extra_modules(user_params)
    extra_keys = filter_keys(user_params)
    extra_keys.map { |e| e.remove('-' + id.to_s).concat('?') }
  end

  def project?(project)
    Rails.cache.fetch("#{cache_key}/#{project}", expires_in: 2.hours) do
      Medium.where(sort: sort[project]).to_a.any? { |m| m.course == self }
    end
  end

  def sort
    { 'kaviar' => ['Kaviar'], 'sesam' => ['Sesam'], 'kiwi' => ['Kiwi'],
      'keks' => ['KeksQuiz'], 'reste' => ['Reste'],
      'erdbeere' => ['Erdbeere'] }
  end
end

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
    Rails.cache.fetch("#{cache_key}/kaviar", expires_in: 2.hours) do
      Medium.where(sort: 'Kaviar').any? { |m| m.course == self }
    end
  end

  def sesam?
    Rails.cache.fetch("#{cache_key}/sesam", expires_in: 2.hours) do
      Medium.where(sort: 'Sesam').any? { |m| m.course == self }
    end
  end

  def keks?
    Rails.cache.fetch("#{cache_key}/keks", expires_in: 2.hours) do
      Medium.where(sort: ['Keks', 'KeksQuestion']).any? { |m| m.course == self }
    end
  end

  def erdbeere?
    Rails.cache.fetch("#{cache_key}/erdbeere", expires_in: 2.hours) do
      Medium.where(sort: 'Erdbeere').any? { |m| m.course == self }
    end
  end

  def kiwi?
    Rails.cache.fetch("#{cache_key}/kiwi", expires_in: 2.hours) do
      Medium.where(sort: 'Kiwi').any? { |m| m.course == self }
    end
  end

  def reste?
    Rails.cache.fetch("#{cache_key}/reste", expires_in: 2.hours) do
      Medium.where(sort: 'Reste').any? { |m| m.course == self }
    end
  end

  def available_extras
    hash = { 'news?' => news.present?, 'sesam?' => sesam?, 'keks?' => keks?,
             'erdbeere?' => erdbeere?, 'kiwi?' => kiwi?, 'reste?' => reste? }
    hash.keys.select { |k| hash[k] == true }
  end

  def kaviar_lectures
    lectures.select { |l| l.kaviar? }
  end

  def kaviar_lectures_by_date
    kaviar_lectures.sort do |i, j|
      j.term.begin_date <=> i.term.begin_date
    end
  end

  def lectures_by_date
    lectures.to_a.sort do |i, j|
      j.term.begin_date <=> i.term.begin_date
    end
  end

  def extras(user_params)
    all_keys = user_params.keys
    extra_keys = all_keys.select do |k|
      k.end_with?('-' + id.to_s) && !k.include?('lecture-') &&
        !k.start_with?('course-') && user_params[k] == '1'
    end
    extra_modules = extra_keys.map { |e| e.remove('-' + id.to_s).concat('?') }
    modules = {}
    available_extras.each { |e| modules[e] = false }
    extra_modules.each { |e| modules[e] = true }
    modules['primary_lecture_id'] = user_params['primary_lecture-' + id.to_s]
    modules
  end

  def course
    self
  end

  def lecture
  end

  def lesson
  end

  def primary_lecture(user)
    user_join = CourseUserJoin.where(course: self, user: user)
    return if user_join.empty?
    Lecture.find_by_id(user_join.first.primary_lecture_id)
  end
end

# Course class
class Course < ApplicationRecord
  has_many :lectures, dependent: :destroy
  has_many :course_tag_joins
  has_many :tags, through: :course_tag_joins
  has_many :media, as: :teachable
  has_many :course_user_joins, dependent: :destroy
  has_many :users, through: :course_user_joins
  validates :title, presence: true, uniqueness: true
  validates :short_title, presence: true, uniqueness: true

  def to_label
    title
  end

  def description
    { general: title }
  end

  def kaviar?
    Medium.where(sort: 'Kaviar').any? { |m| m.course == self }
  end

  def sesam?
    Medium.where(sort: 'Sesam').any? { |m| m.course == self }
  end

  def keks?
    Medium.where(sort: ['Keks', 'KeksQuestion']).any? { |m| m.course == self }
  end

  def erdbeere?
    Medium.where(sort: 'Erdbeere').any? { |m| m.course == self }
  end

  def kiwi?
    Medium.where(sort: 'Kiwi').any? { |m| m.course == self }
  end

  def reste?
    Medium.where(sort: 'Reste').any? { |m| m.course == self }
  end

  def available_extras
    hash = { 'news' => news.present?, 'sesam' => sesam?, 'keks' => keks?,
             'erdbeere' => erdbeere?, 'kiwi' => kiwi?, 'reste' => reste? }
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
      k.end_with?('-' + id.to_s) && !k.start_with?('lecture-') &&
        !k.start_with?('course-') && user_params[k] == '1'
    end
    extra_modules = extra_keys.map{ |e| e.remove('-' + id.to_s) }
    modules = {}
    available_extras.each { |e| modules[e] = false }
    extra_modules.each { |e| modules[e] = true }
    modules
  end

  def course
    self
  end

  def lecture
  end

  def lesson
  end
end

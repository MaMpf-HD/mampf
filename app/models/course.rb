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

  def kaviar
    return if lectures.empty?
    return true if lectures.map(&:kaviar).include?(true)
    false
  end

  def sesam
    return if lectures.empty?
    return true if lectures.map(&:sesam).include?(true)
    false
  end

  def keks
    return if lectures.empty?
    return true if lectures.map(&:keks).include?(true)
    false
  end

  def erdbeere
    return if lectures.empty?
    return true if lectures.map(&:erdbeere).include?(true)
    false
  end

  def kiwi
    return if lectures.empty?
    return true if lectures.map(&:kiwi).include?(true)
    false
  end

  def reste
    return if lectures.empty?
    return true if lectures.map(&:reste).include?(true)
    false
  end

  def kaviar_lectures
    lectures.where(kaviar: true)
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

end

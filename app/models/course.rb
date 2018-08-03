# Course class
class Course < ApplicationRecord
  has_many :lectures, dependent: :destroy
  has_many :course_tag_joins
  has_many :tags, through: :course_tag_joins
  has_many :media, as: :teachable
  validates :title, presence: true, uniqueness: true
  validates :short_title, presence: true, uniqueness: true

  def to_label
    title
  end

  def description
    { general: title }
  end
end

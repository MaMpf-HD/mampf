# User class
class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  has_many :lecture_user_joins, dependent: :destroy
  has_many :lectures, through: :lecture_user_joins, dependent: :destroy
  before_save :set_defaults

  def related_lectures
    return if subscription_type.nil?
    case subscription_type
    when 1
      ids = lectures.all.map { |l| l.preceding_lectures.pluck(:id) }.flatten +
            lectures.all.pluck(:id)
      return Lecture.where(id: ids)
    when 2
      return Lecture.all
    when 3
      return lectures
    end
  end

  private

  def set_defaults
    self.lectures = [Lecture.first] if lectures.empty?
    self.subscription_type = 1 if subscription_type.nil?
    self.admin = false if admin.nil?
  end
end

class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  has_many :lecture_user_joins, dependent: :destroy
  has_many :lectures, through: :lecture_user_joins, dependent: :destroy

  def related_lectures
    return if subscription_type.nil?
    case subscription_type
    when 1
      ids = lectures.all.map{ |l| l.preceding_lectures.pluck(:id)}.flatten +
            lectures.all.pluck(:id)
      return Lecture.where(id: ids)
    when 2
      return Lecture.all
    when 3
      return lectures
    end
  end
end

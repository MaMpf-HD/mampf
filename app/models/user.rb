class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  has_many :lecture_user_joins, dependent: :destroy
  has_many :lectures, through: :lecture_user_joins, dependent: :destroy
  after_create :subscribe_all_lectures
  after_create :set_subscription_type
  after_create :set_admin_false

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

private

  def subscribe_all_lectures
    self.update(lectures: [Lecture.first])
  end

  def set_subscription_type
    self.update(subscription_type: 1)
  end

  def set_admin_false
    self.update(admin: false)
  end
end

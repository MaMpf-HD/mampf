# User class
class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :lecture_user_joins, dependent: :destroy
  has_many :lectures, through: :lecture_user_joins, dependent: :destroy
  before_save :set_defaults
  validate :consented?
  after_create :set_consented_at

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
    self.lectures = [Lecture.last] if lectures.empty? && Lecture.any?
    self.subscription_type = 1 if subscription_type.nil?
    self.admin = false if admin.nil?
  end

  def consented?
    return true if consents
    errors.add(:base, 'Du hast der Einwilligung zur Speicherung und Verarbeitung' \
                      ' Deiner Daten gemäß der Datenschutzerklärung nicht zugestimmt.')
    false
  end

  def set_consented_at
    update(consented_at: Time.now)
  end
end

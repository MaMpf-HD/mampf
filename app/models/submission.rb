class Submission < ApplicationRecord
  belongs_to :tutorial
  belongs_to :assignment

  has_many :user_submission_joins, dependent: :destroy
  has_many :users, through: :user_submission_joins

  validate :matching_lecture

  before_create :set_token

  private

	def matching_lecture
		return true if tutorial.lecture == assignment.lecture
		errors.add(:tutorial, :lecture_not_matching)
	end

  def set_token
    self.token = generate_token
  end

  def generate_token
    loop do
      random_token = SecureRandom.base58(6)
      break random_token unless Submission.exists?(token: random_token)
    end
  end
end

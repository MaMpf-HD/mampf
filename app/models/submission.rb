class Submission < ApplicationRecord
  belongs_to :tutorial
  belongs_to :assignment

  has_many :user_submission_joins, dependent: :destroy
  has_many :users, through: :user_submission_joins

  include SubmissionUploader[:manuscript]

  validate :matching_lecture

  before_create :set_token

  def partners_of_user(user)
    return unless user.in?(users)
    users - [user]
  end

  def manuscript_filename
    return unless manuscript.present?
    manuscript.metadata['filename']
  end

  def manuscript_size
    return unless manuscript.present?
    manuscript.metadata['size']
  end

  def preceding_tutorial(user)
    assignment.previous.submission(user)
  end

  def invited_users
  	User.where(id: invited_user_ids)
  end

  def self.generate_token
    loop do
      random_token = SecureRandom.base58(6)
      break random_token unless Submission.exists?(token: random_token)
    end
  end

  def admissible_invitees(user)
  	user.submission_partners(assignment.lecture) - users
  end

  private

	def matching_lecture
		return true if tutorial.lecture == assignment.lecture
		errors.add(:tutorial, :lecture_not_matching)
	end

  def set_token
    self.token = Submission.generate_token
  end
end

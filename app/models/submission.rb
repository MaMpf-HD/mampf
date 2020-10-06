class Submission < ApplicationRecord
  belongs_to :tutorial
  belongs_to :assignment

  has_many :user_submission_joins, dependent: :destroy
  has_many :users, through: :user_submission_joins

  self.implicit_order_column = "created_at"

  include SubmissionUploader[:manuscript]
  include CorrectionUploader[:correction]

  scope :proper, -> { where.not(manuscript_data: nil) }

  validate :matching_lecture, if: :tutorial

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

  def preceding_tutorial(user)subm
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

  def in_time?
    (last_modification_by_users_at || created_at) <= assignment.deadline
  end

  def too_late?
    !in_time?
  end

  def not_updatable?
    assignment.totally_expired? || correction.present?
  end

  private

	def matching_lecture
		return true if tutorial&.lecture == assignment.lecture
		errors.add(:tutorial, :lecture_not_matching)
	end

  def set_token
    self.token = Submission.generate_token
  end
end

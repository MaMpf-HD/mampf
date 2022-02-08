class UserSubmissionJoin < ApplicationRecord
  belongs_to :user
  belongs_to :submission

  validate :only_one_per_assignment, on: :create
  validate :max_team_size, on: :create

  def self.to_be_deleted_user_ids
    UserSubmissionJoin.where(submission: Submission.to_be_deleted).pluck(:user_id).uniq
  end

  def assignment
  	submission.assignment
  end

  private

  def only_one_per_assignment
  	if UserSubmissionJoin.where(user: user, submission: assignment.submissions)
	   										 .none?
	   	return true
	  end
  	errors.add(:base, :only_one_per_assignment)
  end

  def max_team_size
  	lecture = submission.assignment.lecture
  	return true unless lecture.submission_max_team_size
  	return true if submission.users.size < lecture.submission_max_team_size
  	errors.add(:base, :team_size)
  end
end

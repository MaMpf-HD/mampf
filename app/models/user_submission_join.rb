class UserSubmissionJoin < ApplicationRecord
  belongs_to :user
  belongs_to :submission

  validate :only_one_per_assignment

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

end

class UserSubmissionJoin < ApplicationRecord
  belongs_to :user
  belongs_to :submission

  validate :only_one_per_assignment, on: :create
  validate :max_team_size, on: :create
  validate :same_tutorial, on: :create

  delegate :assignment, to: :submission

  private

    def only_one_per_assignment
      if UserSubmissionJoin.where(user: user,
                                  submission: assignment.submissions)
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

    # Where the lecture keeps teams within one tutorial, only somebody who
    # sits in the hand-in's tutorial joins it.
    def same_tutorial
      return if submission.assignment.lecture.cross_tutorial_teams?
      return if TutorialMembership.exists?(user: user, tutorial_id: submission.tutorial_id)

      errors.add(:base, :other_tutorial)
    end
end

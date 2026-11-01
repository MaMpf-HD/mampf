class Cohort < ApplicationRecord
  include Registration::Registerable
  include Rosters::Rosterable

  belongs_to :context, polymorphic: true

  has_many :cohort_memberships, dependent: :destroy
  has_many :users, through: :cohort_memberships
  has_many :members, through: :cohort_memberships, source: :user

  has_many :cohort_tutor_joins, dependent: :destroy
  has_many :tutors, through: :cohort_tutor_joins

  scope :for_lectures, lambda { |lectures|
    where(context_type: "Lecture", context_id: lectures)
  }

  attr_readonly :propagate_to_lecture

  validates :title, presence: true,
                    uniqueness: { scope: [:context_type, :context_id] }
  validates :capacity, numericality: { greater_than_or_equal_to: 0, allow_nil: true }

  def roster_entries
    cohort_memberships
  end

  def lecture
    context if context.is_a?(Lecture)
  end

  # Like #lecture, but without loading the context — callers that only need the
  # id are often iterating over many cohorts.
  def lecture_id
    context_id if context_type == "Lecture"
  end

  def registration_title
    title
  end

  def tutor_names
    tutors.map(&:tutorial_name).join(", ").presence
  end

  def exclusive_assignment?
    false
  end

  FormerMembership = Struct.new(:users, :left_lecture_ids)

  # Members do not block deleting a cohort, only a campaign that is not
  # completed does.
  def destruction_blockers_with_members
    destruction_blockers - [:roster_not_empty]
  end

  # Deletes the cohort with its memberships. Members for whom it was the last
  # group that enrolled them are no longer enrolled, as when the staff remove
  # them from it. Locks the cohort, then the lecture, like
  # MaintenanceService#remove_user!. Returns a FormerMembership, or nil while a
  # campaign that is not completed still contains the cohort.
  def destroy_with_members(by: nil)
    transaction do
      lock!
      lecture&.lock!
      users = members.to_a
      left_ids = leave_lecture!(users, by)
      cohort_memberships.destroy_all
      raise(ActiveRecord::Rollback) unless destroy

      FormerMembership.new(users, left_ids)
    end
  end

  # Members in no tutorial, talk, exam list or other cohort of the lecture,
  # whom deleting the cohort leaves without a group.
  def member_ids_leaving_the_lecture
    Rosters::LectureLeave.only_place_user_ids(self, cohort_memberships.pluck(:user_id))
  end

  def members_without_other_group
    return members unless lecture

    lecture.group_memberships(cohorts: lecture.cohorts.where.not(id: id))
           .reduce(members) { |scope, memberships| scope.where.not(id: memberships) }
  end

  private

    def leave_lecture!(users, by)
      left_ids = member_ids_leaving_the_lecture
      service = Rosters::MaintenanceService.new
      users.select { |user| user.id.in?(left_ids) }
           .each { |user| service.remove_user!(user, self, notify: false, by: by) }
      left_ids
    end
end

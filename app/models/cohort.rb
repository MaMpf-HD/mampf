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

  # The members a deleted cohort had, and of those the ones who left the
  # lecture with it.
  Deletion = Struct.new(:former_members, :left_lecture_ids)

  # Members do not block deleting a cohort, only a campaign that is not
  # completed does.
  def destruction_blockers_with_members
    destruction_blockers - [:roster_not_empty]
  end

  # Deletes the cohort together with its memberships. Whoever loses their
  # last place with it leaves the lecture, as on removal by hand (see
  # Rosters::MaintenanceService#remove_user!), whose lock order this
  # follows: campaigns, cohort, lecture. Returns a Deletion, or nil when a
  # campaign still holds the cohort.
  def destroy_with_members(by: nil)
    transaction do
      lock_running_campaigns!
      lock!
      lecture&.lock!
      former_members = members.to_a
      left_ids = leave_lecture!(former_members, by)
      cohort_memberships.destroy_all
      raise(ActiveRecord::Rollback) unless destroy

      Deletion.new(former_members, left_ids)
    end
  end

  # Members for whom the cohort is the last place in the lecture, who leave
  # the lecture when it is deleted.
  def member_ids_leaving_the_lecture
    Rosters::LectureLeave.only_place_user_ids(self, cohort_memberships.pluck(:user_id))
  end

  # Members in no tutorial, talk, exam list or other cohort of the lecture,
  # whom deleting the cohort leaves without a group.
  def members_without_other_group
    return members unless lecture

    members.where.not(id: TutorialMembership.where(tutorial: Tutorial.where(lecture: lecture))
                                            .select(:user_id))
           .where.not(id: SpeakerTalkJoin.where(talk: Talk.where(lecture: lecture))
                                         .select(:speaker_id))
           .where.not(id: CohortMembership.where(cohort: lecture.cohorts.where.not(id: id))
                                          .select(:user_id))
           .where.not(id: ExamRosterEntry.active.where(exam: lecture.exams).select(:user_id))
  end

  private

    # Leaving the lecture withdraws the registrations there, so their
    # campaigns come first; only a cohort with lecture enrollment takes
    # anyone out.
    def lock_running_campaigns!
      return unless place? && lecture

      Registration::Campaign.running.where(campaignable: lecture).order(:id).lock.load
    end

    def leave_lecture!(former_members, by)
      left_ids = member_ids_leaving_the_lecture
      service = Rosters::MaintenanceService.new
      former_members.select { |user| user.id.in?(left_ids) }
                    .each { |user| service.remove_user!(user, self, notify: false, by: by) }
      left_ids
    end
end

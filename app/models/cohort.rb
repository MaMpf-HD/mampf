class Cohort < ApplicationRecord
  include Registration::Registerable
  include Rosters::Rosterable

  belongs_to :context, polymorphic: true

  has_many :cohort_memberships, dependent: :destroy
  has_many :users, through: :cohort_memberships
  has_many :members, through: :cohort_memberships, source: :user

  has_many :cohort_tutor_joins, dependent: :destroy
  has_many :tutors, -> { by_last_name }, through: :cohort_tutor_joins

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

  # Members do not block deleting a cohort, only a campaign that is not
  # completed does; the lecture keeps whom the cohort enrolled.
  def destruction_blockers_with_members
    destruction_blockers - [:roster_not_empty]
  end

  # Deletes the cohort together with its memberships. Returns the former
  # members, or nil when a campaign still holds the cohort.
  def destroy_with_members
    with_lock do
      former_members = members.to_a
      cohort_memberships.destroy_all
      raise(ActiveRecord::Rollback) unless destroy

      former_members
    end
  end

  # Members in no tutorial, talk or other cohort of the lecture, whom
  # deleting the cohort leaves without a group.
  def members_without_other_group
    return members unless lecture

    members.where.not(id: TutorialMembership.where(tutorial: Tutorial.where(lecture: lecture))
                                            .select(:user_id))
           .where.not(id: SpeakerTalkJoin.where(talk: Talk.where(lecture: lecture))
                                         .select(:speaker_id))
           .where.not(id: CohortMembership.where(cohort: lecture.cohorts.where.not(id: id))
                                          .select(:user_id))
  end
end

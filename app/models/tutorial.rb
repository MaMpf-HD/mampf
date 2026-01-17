require "csv"

class Tutorial < ApplicationRecord
  include Registration::Registerable
  include Rosters::Rosterable

  belongs_to :lecture, touch: true

  has_many :tutor_tutorial_joins, dependent: :destroy
  has_many :tutors, through: :tutor_tutorial_joins

  # Roster associations
  has_many :tutorial_memberships, dependent: :destroy
  has_many :members, through: :tutorial_memberships, source: :user

  has_many :submissions, dependent: :destroy

  has_many :claims, as: :claimable, dependent: :destroy

  before_destroy :check_destructibility, prepend: true

  validates :title, uniqueness: { scope: [:lecture_id] }, presence: true
  validate :lecture_must_not_be_seminar

  def title_with_tutors
    return "#{title}, #{I18n.t("basics.tba")}" unless tutors.any?

    "#{title}, #{tutor_names}"
  end

  def registration_title
    return title unless tutors.any?

    "#{title} (#{tutor_names})"
  end

  def tutor_names
    return unless tutors.any?

    tutors.map(&:tutorial_name).join(", ")
  end

  def destructible?
    super && Submission.where(tutorial: self).proper.none?
  end

  def teams_to_csv(assignment)
    submissions = Submission.where(tutorial: self, assignment: assignment)
                            .proper.order(:last_modification_by_users_at)
    CSV.generate(headers: false) do |csv|
      submissions.each do |s|
        csv << [s.team]
      end
    end
  end

  def add_tutor(tutor)
    tutors << tutor unless tutors.include?(tutor)
  end

  def roster_entries
    tutorial_memberships
  end

  def materialize_allocation!(user_ids:, campaign:)
    # Enforce uniqueness: A student can only be in one tutorial per lecture.
    # If we are about to add a student to this tutorial, remove them from any other
    # tutorial in the same lecture.
    TutorialMembership.joins(:tutorial)
                      .where(tutorials: { lecture_id: lecture_id })
                      .where.not(tutorial_id: id)
                      .where(user_id: user_ids)
                      .delete_all

    super
  end

  private

    def check_destructibility
      return unless Submission.where(tutorial: self).proper.any?

      errors.add(:base, I18n.t("controllers.tutorials.errors.cannot_delete_with_submissions"))
      throw(:abort)
    end

    def lecture_must_not_be_seminar
      return unless lecture&.seminar?

      errors.add(:lecture, :must_not_be_seminar)
    end
end

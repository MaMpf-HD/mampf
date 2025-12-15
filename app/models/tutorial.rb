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
    Submission.where(tutorial: self).proper.none?
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

  def add_user_to_roster!(user, source_campaign)
    TutorialMembership.create!(user: user, tutorial: self, source_campaign: source_campaign)
  end

  def remove_user_from_roster!(user)
    tutorial_memberships.where(user: user).destroy_all
  end

  private

    def check_destructibility
      throw(:abort) unless destructible?
      true
    end
end

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
  validate :lecture_id_immutable, on: :update

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
    tutor_tutorial_joins.create_or_find_by(tutor: tutor)
                        .previously_new_record?
  end

  def roster_entries
    tutorial_memberships
  end

  def add_user_to_roster!(user, source_campaign = nil)
    super
  rescue ActiveRecord::RecordNotUnique
    conflicting = TutorialMembership
                  .where(lecture_id: lecture_id, user_id: user.id)
                  .where.not(tutorial_id: id)
                  .first
    raise(Rosters::UserAlreadyInBundleError, conflicting&.tutorial)
  end

  private

    def lecture_id_immutable
      errors.add(:lecture_id, :immutable) if lecture_id_changed?
    end

    # Overrides Rosters::Rosterable#add_missing_users! to inject lecture_id
    # into the bulk insert and resolve conflicts on the (user_id, lecture_id)
    # unique index with an upsert. The concern's default insert_all has no
    # lecture_id and uses ON CONFLICT DO NOTHING, which would silently drop
    # users already assigned to a sibling tutorial in the same lecture.
    def add_missing_users!(target_ids, current_ids, campaign)
      users_to_add = target_ids - current_ids
      return if users_to_add.empty?

      scope_attrs = roster_entries.scope_attributes
      now = Time.current
      attributes = users_to_add.map do |uid|
        {
          user_id: uid,
          lecture_id: lecture_id,
          source_campaign_id: campaign.id,
          created_at: now,
          updated_at: now
        }.merge(scope_attrs)
      end

      roster_entries.upsert_all( # rubocop:disable Rails/SkipsModelValidations
        attributes,
        unique_by: :index_tutorial_memberships_on_user_id_and_lecture_id,
        update_only: [:tutorial_id, :source_campaign_id]
      )
    end

    def check_destructibility
      return if destructible?

      if submissions.proper.exists?
        errors.add(:base,
                   I18n.t("controllers.tutorials.errors.cannot_delete_with_submissions"))
      elsif in_campaign?
        errors.add(:base, I18n.t("roster.errors.cannot_delete_in_campaign"))
      elsif !roster_empty?
        errors.add(:base, I18n.t("roster.errors.cannot_delete_not_empty"))
      end

      throw(:abort)
    end

    def lecture_must_not_be_seminar
      return unless lecture&.seminar?

      errors.add(:lecture, :must_not_be_seminar)
    end
end

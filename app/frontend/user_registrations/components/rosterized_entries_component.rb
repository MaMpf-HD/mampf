# Renders the student's registration-outcome notices on the registration page:
# the confirmed/rosterized entries (including preference-fulfillment messaging)
# and the notice for preference-based campaigns where the student was not
# allocated a spot.
class RosterizedEntriesComponent < ViewComponent::Base
  include EligibilityHelper

  def initialize(rosterized_entries:, lecture:, user:)
    super()
    @rosterized_entries = rosterized_entries || []
    @lecture = lecture
    @user = user
  end

  attr_reader :rosterized_entries, :lecture, :user

  # Messages shown in the confirmed-entries kicker. Falls back to the generic
  # "confirmed cases" notice when no preference-based messaging applies.
  def notice_messages
    return [] if rosterized_entries.blank? && policy_rejection_results.present?
    return [unassigned_notice] if rosterized_entries.blank?

    messages = rosterized_entries.filter_map do |rosterable|
      preference_notice_message(rosterable)
    end

    messages.presence || [default_notice]
  end

  def custom_notice?
    rosterized_entries.blank? || notice_messages != [default_notice]
  end

  def neutral_notice?
    rosterized_entries.blank?
  end

  def unremovable_assignment_notice?
    self_roster_availability.blocked_by_unremovable_assignment?
  end

  def default_notice
    t("registration.user_registration.index.confirmed_cases")
  end

  def entry_type(rosterable)
    helpers.roster_type_text(rosterable)
  end

  def entry_description(rosterable)
    return unless rosterable.respond_to?(:description)

    rosterable.description.presence
  end

  def entry_metadata_rows(rosterable)
    [entry_person_row(rosterable),
     entry_location_row(rosterable),
     entry_participants_row(rosterable)].compact
  end

  # Preference-based campaigns where the student was rejected (not allocated a
  # spot), each paired with the labels of the preferences they submitted.
  def unallocated_results
    @unallocated_results ||= unallocated_campaigns.map do |campaign|
      {
        campaign: campaign,
        preferences: unallocated_labels(
          rejected_registrations_by_campaign[campaign.id] || []
        )
      }
    end
  end

  def policy_rejection_results
    @policy_rejection_results ||= policy_rejected_campaigns.map do |campaign|
      messages = failed_policy_messages(campaign)

      {
        campaign: campaign,
        messages: messages.presence || [t("registration.user_registration.status.rejected")]
      }
    end
  end

  def campaign_title(campaign)
    description = campaign.description.to_s.strip
    return description if description.present?

    t("registration.user_registration.campaign_main")
  end

  private

    def unassigned_notice
      if pending_preference_submissions?
        t("registration.user_registration.index.pending_preference_notice")
      else
        t("registration.user_registration.index.unassigned_notice")
      end
    end

    def self_roster_availability
      @self_roster_availability ||= Rosters::SelfRosterAvailability.new(lecture, user)
    end

    def preference_notice_message(rosterable)
      membership = entry_membership(rosterable)
      campaign = membership&.source_campaign
      return unless campaign&.preference_based?

      registrations = preference_registrations(campaign)
      return if registrations.blank?

      fulfilled = registrations.find do |registration|
        registration.registration_item.registerable == rosterable
      end

      if fulfilled
        t("registration.user_registration.index.fulfilled_preference_notice",
          rank: preference_rank_label(fulfilled.preference_rank))
      else
        t("registration.user_registration.index.unfulfilled_preferences_notice",
          preferences: preference_labels(registrations))
      end
    end

    def entry_membership(rosterable)
      rosterable.roster_entries
                .includes(:source_campaign)
                .find_by(rosterable.roster_user_id_column => user.id)
    end

    def preference_registrations(campaign)
      campaign.user_registrations
              .includes(registration_item: :registerable)
              .where(user_id: user.id)
              .where.not(preference_rank: nil)
              .order(:preference_rank)
              .to_a
    end

    def preference_labels(registrations)
      registrations.map do |registration|
        rank = t("registration.user_registration.preference_rank_options." \
                 "#{registration.preference_rank}")
        "#{rank} #{registration.registration_item.title}"
      end.join(", ")
    end

    def preference_rank_label(rank)
      t("registration.user_registration.index.fulfilled_preference_ranks.#{rank}",
        default: t("registration.user_registration.preference_rank_options.#{rank}"))
    end

    def entry_person_row(rosterable)
      case rosterable
      when Tutorial
        {
          icon: "bi-person",
          label: t("basics.tutor"),
          value: entry_tutor_value(rosterable)
        }
      when Talk
        {
          icon: "bi-mic",
          label: t("basics.speakers"),
          value: helpers.roster_tutors_text(rosterable)
        }
      end
    end

    def entry_location_row(rosterable)
      return unless rosterable.respond_to?(:location)
      return if rosterable.location.blank?

      {
        icon: "bi-geo-alt",
        label: t("basics.location"),
        value: rosterable.location
      }
    end

    def entry_participants_row(rosterable)
      {
        icon: "bi-people",
        label: t("basics.participants"),
        value: rosterable.members.size.to_s
      }
    end

    def entry_tutor_value(rosterable)
      return helpers.roster_tutors_text(rosterable) if rosterable.tutors.any?

      content_tag(
        :span,
        "?",
        class: "student-registration-rosterized-unknown",
        title: t("registration.user_registration.index.unknown_tutor"),
        aria: { label: t("registration.user_registration.index.unknown_tutor") }
      )
    end

    def unallocated_campaigns
      @unallocated_campaigns ||= begin
        confirmed_campaign_ids = Registration::UserRegistration
                                 .confirmed
                                 .where(user_id: user.id)
                                 .select(:registration_campaign_id)

        Registration::Campaign
          .where(campaignable: lecture,
                 allocation_mode: :preference_based,
                 status: :completed)
          .joins(:user_registrations)
          .merge(
            Registration::UserRegistration.rejected
                                         .with_capacity_or_legacy_rejection_reason
                                         .where(user_id: user.id)
          )
          .where.not(id: confirmed_campaign_ids)
          .distinct
          .order(updated_at: :desc)
          .to_a
      end
    end

    def pending_preference_submissions?
      @pending_preference_submissions ||= Registration::UserRegistration
                                          .pending
                                          .exists?(
                                            user_id: user.id,
                                            registration_campaign_id: preference_campaign_ids
                                          )
    end

    def preference_campaign_ids
      @preference_campaign_ids ||= Registration::Campaign
                                   .where(campaignable: lecture,
                                          allocation_mode: :preference_based)
                                   .select(:id)
    end

    def rejected_registrations_by_campaign
      @rejected_registrations_by_campaign ||=
        Registration::UserRegistration
        .rejected
        .with_capacity_or_legacy_rejection_reason
        .where(user_id: user.id,
               registration_campaign_id: unallocated_campaigns.map(&:id))
        .includes(registration_item: :registerable)
        .order(:preference_rank)
        .group_by(&:registration_campaign_id)
    end

    def policy_rejected_campaigns
      @policy_rejected_campaigns ||= begin
        active_campaign_ids = Registration::UserRegistration
                              .where(user_id: user.id,
                                     status: [:confirmed, :pending])
                              .select(:registration_campaign_id)

        Registration::Campaign
          .where(campaignable: lecture, status: :completed)
          .joins(:user_registrations)
          .merge(
            Registration::UserRegistration.rejected
                                         .with_policy_rejection_reason
                                         .where(user_id: user.id)
          )
          .where.not(id: active_campaign_ids)
          .distinct
          .order(updated_at: :desc)
          .to_a
      end
    end

    def policy_rejected_registrations_by_campaign
      @policy_rejected_registrations_by_campaign ||=
        Registration::UserRegistration
        .rejected
        .with_policy_rejection_reason
        .where(
          user_id: user.id,
          registration_campaign_id: policy_rejected_campaigns.map(&:id)
        )
        .includes(:registration_item)
        .group_by(&:registration_campaign_id)
    end

    def failed_policy_messages(campaign)
      UserRegistrations::EligibilityTraceService.new(
        campaign,
        user,
        phase: :finalization
      ).call.reject { |policy| policy.dig(:outcome, :pass) }
                                                .map do |policy|
        eligibility_failure_message(policy,
                                    user: user)
      end
                                                .uniq
    end

    def unallocated_labels(registrations)
      registrations.map do |registration|
        rank_label = t(
          "registration.user_registration.preference_rank_options." \
          "#{registration.preference_rank}",
          default: registration.preference_rank.to_s
        )
        "#{rank_label} #{registration.registration_item.title}"
      end
    end
end

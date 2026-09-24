class CampaignCardComponent < ViewComponent::Base
  include EligibilityHelper

  # `part` renders only the summary or only the body, so a Turbo Stream can
  # refresh one campaign without closing it or touching the others.
  def initialize(details:, campaign:, part: nil)
    super()
    @details = details
    @campaign = campaign
    @part = part
  end

  attr_reader :details, :campaign, :part

  def anchor_id
    dom_id(campaign, :student_registration)
  end

  def summary_id
    dom_id(campaign, :student_registration_summary)
  end

  def body_id
    dom_id(campaign, :student_registration_body)
  end

  def registered_items
    @registered_items ||= items.select { |item| item.user_registered?(helpers.current_user) }
  end

  def preferences_saved?
    Array(item_preferences).any? { |pref| pref.respond_to?(:item) }
  end

  # Says in the collapsed row what the student still has to do; once they have
  # registered or chosen, the participation section reports it instead.
  def summary_badge
    return [:bad, t("registration.user_registration.summary.requirement_missing")] if ineligible?
    return [:bad, t("registration.user_registration.summary.blocked")] if blocked?
    return if registered_items.any? || preferences_saved?

    key = campaign.preference_based? ? "no_preferences" : "not_registered"
    [:warn, t("registration.user_registration.summary.#{key}")]
  end

  def summary_lines
    [deadline_line, ineligible? ? ineligible_line : mode_line].compact
  end

  def cta_label
    return t("registration.user_registration.summary.details") if ineligible? || blocked?
    return t("registration.user_registration.summary.change") if registered_items.any?
    return t("registration.user_registration.summary.change_preferences") if preferences_saved?
    return t("registration.user_registration.summary.choose") if campaign.preference_based?
    return t("registration.user_registration.summary.register") if campaign.exam_campaign?

    t("registration.user_registration.summary.show_and_register")
  end

  def cta_primary?
    summary_badge&.first == :warn
  end

  delegate :eligibility, :finalization_eligibility, :items, :item_preferences,
           to: :details

  def readonly?
    helpers.student_registration_readonly?(campaign)
  end

  def ineligible?
    !campaign.completed? && failed_ineligible_policies.any?
  end

  def failed_ineligible_policies
    @failed_ineligible_policies ||= failed_eligibility_policies(eligibility)
  end

  def failed_finalization_policies
    @failed_finalization_policies ||=
      if ineligible?
        []
      else
        failed_eligibility_policies(finalization_eligibility)
      end
  end

  def finalization_policy_warning?
    failed_finalization_policies.any?
  end

  def policy_overview_sections
    @policy_overview_sections ||=
      if eligibility.blank? && finalization_eligibility.blank?
        []
      else
        [
          policy_section(
            title: I18n.t("registration.user_registration.policy_overview." \
                          "registration_title"),
            description: I18n.t("registration.user_registration.policy_overview." \
                                "registration_description"),
            empty_text: I18n.t("registration.user_registration.policy_overview." \
                               "registration_empty"),
            context: :registration,
            policies: eligibility
          ),
          policy_section(
            title: I18n.t("registration.user_registration.policy_overview." \
                          "finalization_title"),
            description: I18n.t("registration.user_registration.policy_overview." \
                                "finalization_description"),
            empty_text: I18n.t("registration.user_registration.policy_overview." \
                               "finalization_empty"),
            context: :finalization_warning,
            policies: finalization_eligibility
          )
        ]
      end
  end

  def policy_overview?
    policy_overview_sections.any?
  end

  def registration_actions_disabled?
    readonly? || ineligible? || blocked?
  end

  # Every option is a tutorial and the student may not leave theirs.
  def blocked?
    return @blocked if defined?(@blocked)

    @blocked = !ineligible? && helpers.registration_campaign_blocked?(campaign, items)
  end

  def campaign_title
    campaign.student_facing_title
  end

  def instruction
    helpers.student_registration_instruction(campaign, items)
  end

  def policy_overview_hint(policy, context:)
    eligibility_policy_hint(policy, user: helpers.current_user, context: context)
  end

  private

    def deadline_line
      deadline = campaign.registration_deadline
      days = (deadline.to_date - Time.zone.today).to_i
      soon = t("registration.user_registration.summary.days_left", count: days) if
        days.between?(0, 6)
      [t("registration.user_registration.summary.deadline",
         deadline: helpers.format_date(deadline)), soon].compact.join(" · ")
    end

    def ineligible_line
      policy = failed_ineligible_policies.first
      eligibility_failure_message(policy, user: helpers.current_user, context: :registration)
    end

    def mode_line
      if campaign.preference_based?
        t("registration.user_registration.summary.preference_mode",
          count: helpers.preference_rank_count(items), options: items.size)
      elsif campaign.exam_campaign?
        item = items.first
        free = item&.capacity && [item.capacity - item.item_capacity_used, 0].max
        free ? t("registration.user_registration.summary.exam_places", count: free) : nil
      else
        open = items.count(&:still_has_capacity?)
        t("registration.user_registration.summary.fcfs_mode", open: open, total: items.size)
      end
    end

    def failed_eligibility_policies(policies)
      policies.reject { |policy| policy.dig(:outcome, :pass) }
    end

    def policy_section(title:, description:, empty_text:, context:, policies:)
      {
        title: title,
        description: description,
        empty_text: empty_text,
        context: context,
        policies: policies
      }
    end
end

class CampaignCardComponent < ViewComponent::Base
  include EligibilityHelper

  def initialize(details:, campaign:)
    super()
    @details = details
    @campaign = campaign
  end

  attr_reader :details, :campaign

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
    readonly? || ineligible?
  end

  def notices_present?
    readonly? || ineligible? || finalization_policy_warning?
  end

  def closed_early?
    helpers.closed_early?(campaign)
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

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

  def main_disabled?
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

  private

    def failed_eligibility_policies(policies)
      policies.reject { |policy| policy.dig(:outcome, :pass) }
    end
end

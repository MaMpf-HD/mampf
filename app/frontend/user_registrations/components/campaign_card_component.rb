class CampaignCardComponent < ViewComponent::Base
  include EligibilityHelper

  def initialize(details:, campaign:)
    super()
    @details = details
    @campaign = campaign
  end

  attr_reader :details, :campaign

  delegate :eligibility, to: :details

  delegate :finalization_eligibility, to: :details

  delegate :items, to: :details

  delegate :item_preferences, to: :details

  def readonly?
    helpers.student_registration_readonly?(campaign)
  end

  def eligible_for_registration?(eligibility)
    eligibility.all? { |policy| policy.dig(:outcome, :pass) }
  end

  def ineligible?
    campaign.status != "completed" && !eligible_for_registration?(eligibility)
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
    helpers.student_registration_campaign_title(campaign)
  end

  def instruction
    helpers.student_registration_instruction(campaign, items)
  end

  private

    def failed_eligibility_policies(eligibility)
      eligibility.reject { |policy| policy.dig(:outcome, :pass) }
    end
end

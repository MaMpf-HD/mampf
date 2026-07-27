module UserRegistrations
  # Adds a human-readable prerequisite-campaign title to a policy config for
  # display. Shared by the live eligibility trace and the historical rejection
  # trace so both decorate prerequisite policies identically.
  module PrerequisiteCampaignDecoration
    PREREQUISITE_CAMPAIGN_KIND = "prerequisite_campaign".freeze

    module_function

    # Returns a copy of the policy config with a "prerequisite_campaign" title
    # added. The original config is never mutated.
    def decorate_config(config)
      config = config.to_h.deep_dup
      campaign = Registration::Campaign.find_by(
        id: config["prerequisite_campaign_id"]
      )
      config["prerequisite_campaign"] = if campaign
        campaign.student_facing_title
      else
        I18n.t("registration.campaign.not_found")
      end

      config
    end
  end
end

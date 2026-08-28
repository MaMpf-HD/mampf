module Demo
  # A campaign that is under way, or that somebody has already registered for,
  # refuses to be destroyed -- rightly, in an app where that would drop what
  # students did. The demo data has to be able to start over all the same.
  module CampaignCleanup
    module_function

    def discard!(campaign)
      return if campaign.nil?

      campaign.user_registrations.destroy_all
      draft!(campaign)
      campaign.destroy!
    end

    # Everything a campaignable has, in the order the app allows: a policy only
    # goes while its campaign is a draft, and a campaign only goes once no other
    # one names it as a prerequisite.
    def discard_all!(campaignable, except: nil)
      campaigns = Registration::Campaign.where(campaignable: campaignable)
      campaigns = campaigns.where.not(description: except) if except.present?

      campaigns.each do |campaign|
        campaign.user_registrations.destroy_all
        draft!(campaign)
      end
      Registration::Policy.where(registration_campaign: campaigns).destroy_all
      campaigns.each(&:destroy!)
    end

    def draft!(campaign)
      # rubocop:disable Rails/SkipsModelValidations
      campaign.update_columns(status: Registration::Campaign.statuses[:draft],
                              updated_at: Time.current)
      # rubocop:enable Rails/SkipsModelValidations
    end
  end
end

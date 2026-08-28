module Demo
  # A campaign that is under way, or that somebody has already registered for,
  # refuses to be destroyed -- rightly, in an app where that would drop what
  # students did. The demo data has to be able to start over all the same.
  module CampaignCleanup
    module_function

    def discard!(campaign)
      return if campaign.nil?

      campaign.user_registrations.destroy_all
      # rubocop:disable Rails/SkipsModelValidations
      campaign.update_columns(status: Registration::Campaign.statuses[:draft],
                              updated_at: Time.current)
      # rubocop:enable Rails/SkipsModelValidations
      campaign.destroy!
    end

    def discard_all!(campaignable, except: nil)
      Registration::Campaign.where(campaignable: campaignable)
                            .where.not(description: except)
                            .find_each { |campaign| discard!(campaign) }
    end
  end
end

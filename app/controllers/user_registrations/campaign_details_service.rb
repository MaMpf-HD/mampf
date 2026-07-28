module UserRegistrations
  class CampaignDetailsService
    Result = Struct.new(:campaign, :eligibility, :items, :item_preferences,
                        :finalization_eligibility,
                        keyword_init: true)

    def initialize(campaign, user)
      @campaign = campaign
      @user = user
    end

    def call
      Result.new(
        campaign: @campaign,
        eligibility: eligibility,
        items: items,
        item_preferences: item_preferences,
        finalization_eligibility: finalization_eligibility
      )
    end

    def eligibility
      eligibility_for(:registration)
    end

    def finalization_eligibility
      eligibility_for(:finalization)
    end

    def items
      @campaign.registration_items.includes(:user_registrations)
    end

    def item_preferences
      return unless @campaign.preference_based?

      UserRegistrations::PreferencesHandler.new.preferences_info(@campaign, @user)
    end

    private

      def eligibility_for(phase)
        UserRegistrations::EligibilityTraceService.new(
          @campaign,
          @user,
          phase: phase
        ).call
      end
  end
end

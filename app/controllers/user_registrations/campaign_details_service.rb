module UserRegistrations
  class CampaignDetailsService
    Result = Struct.new(:campaign, :eligibility, :items, :item_preferences,
                        :finalization_eligibility, :own_registrations, :summary_only,
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
        finalization_eligibility: finalization_eligibility,
        own_registrations: own_registrations,
        summary_only: false
      )
    end

    # What the collapsed row needs: the registration rules and the student's
    # own registrations, which the lecture home has loaded already. The options,
    # the finalization rules and the preferences wait until the row is opened.
    def summary(own_registrations:)
      Result.new(
        campaign: @campaign,
        eligibility: eligibility,
        items: @campaign.registration_items.to_a,
        item_preferences: nil,
        finalization_eligibility: [],
        own_registrations: own_registrations,
        summary_only: true
      )
    end

    def eligibility
      eligibility_for(:registration)
    end

    def finalization_eligibility
      eligibility_for(:finalization)
    end

    def items
      @campaign.registration_items.includes(:registerable)
    end

    def item_preferences
      return unless @campaign.preference_based?

      UserRegistrations::PreferencesHandler.new.preferences_info(@campaign, @user)
    end

    def own_registrations
      @campaign.user_registrations.where(user_id: @user.id)
               .includes(registration_item: :registerable).to_a
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

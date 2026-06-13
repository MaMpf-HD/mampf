module UserRegistrations
  class CampaignDetailsService
    Result = Struct.new(:campaign, :eligibility, :items, :item_preferences,
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
        item_preferences: item_preferences
      )
    end

    def eligibility
      trace = Registration::PolicyEngine.new(@campaign)
                                        .full_trace_with_config_for(@user,
                                                                    phase: :registration)
      trace.each do |policy_result|
        next unless policy_result[:kind] == "prerequisite_campaign"

        id = policy_result[:config]["prerequisite_campaign_id"]
        campaign = Registration::Campaign.find_by(id: id)
        policy_result[:config]["prerequisite_campaign"] =
          if campaign
            "#{campaign&.campaignable&.title}: #{campaign&.description}"
          else
            I18n.t("registration.campaign.not_found")
          end
      end
      trace
    end

    def items
      @campaign.registration_items.includes(:user_registrations)
    end

    def item_preferences
      return unless @campaign.preference_based?

      UserRegistrations::PreferencesHandler.new.preferences_info(@campaign, @user)
    end
  end
end

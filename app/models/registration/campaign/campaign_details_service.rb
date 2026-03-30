module Registration
  class Campaign
    class CampaignDetailsService
      Result = Struct.new(:campaign, :campaignable_host,
                          :eligibility, :items, :item_preferences,
                          :results, keyword_init: true)

      def initialize(campaign, user)
        @campaign = campaign
        @user = user
      end

      def call
        Result.new(
          campaign: @campaign,
          campaignable_host: @campaign.campaignable,
          eligibility: eligibility,
          items: items,
          item_preferences: item_preferences,
          results: results_roster
        )
      end

      def preferences_info
        {
          campaign: @campaign,
          items: items,
          item_preferences: item_preferences
        }
      end

      def eligibility
        trace = PolicyEngine.new(@campaign).full_trace_with_config_for(@user, phase: :registration)
        trace.each do |policy_result|
          next unless policy_result[:kind] == "prerequisite_campaign"

          id = policy_result[:config]["prerequisite_campaign_id"]
          campaign = Registration::Campaign.find_by(id: id)
          policy_result[:config]["prerequisite_campaign"] =
            if campaign
              "#{campaign&.campaignable&.title}: #{campaign&.description}"
            else
              "Campaign not found"
            end
        end
        trace
      end

      def items
        @campaign.registration_items.includes(:user_registrations)
      end

      def item_preferences
        return unless @campaign.preference_based?

        Registration::UserRegistration::PreferencesHandler.new
                                                          .preferences_info(@campaign, @user)
      end

      def results_roster
        items_selected = @campaign.registration_items
                                  .includes(:user_registrations)
                                  .where(user_registrations: { user_id: @user.id })
        items_succeed = Rosters::StudentMaterializedResultResolver
                        .new(@user).succeed_items(@campaign)
        status_items_selected = items_selected.each_with_object({}) do |i, hash|
          hash[i.id] = items_succeed.pluck(:id).include?(i.id) ? "confirmed" : "dismissed"
        end
        { items_selected: items_selected,
          items_succeed: items_succeed,
          status_items_selected: status_items_selected }
      end
    end
  end
end

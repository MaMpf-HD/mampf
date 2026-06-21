module UserRegistrations
  class EligibilityTraceService
    PREREQUISITE_CAMPAIGN_KIND = "prerequisite_campaign".freeze

    def initialize(campaign, user, phase:)
      @campaign = campaign
      @user = user
      @phase = phase
    end

    def call
      trace = Registration::PolicyEngine.new(@campaign)
                                        .full_trace_with_config_for(@user,
                                                                    phase: @phase)
      decorate_prerequisite_campaigns(trace)
      trace
    end

    private

      def decorate_prerequisite_campaigns(trace)
        trace.each do |policy_result|
          next unless policy_result[:kind] == PREREQUISITE_CAMPAIGN_KIND

          config = policy_result[:config]
          id = config["prerequisite_campaign_id"]
          campaign = Registration::Campaign.find_by(id: id)
          config["prerequisite_campaign"] =
            if campaign
              campaign.student_facing_title
            else
              I18n.t("registration.campaign.not_found")
            end
        end
      end
  end
end

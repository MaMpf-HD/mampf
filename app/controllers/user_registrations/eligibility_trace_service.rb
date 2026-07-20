module UserRegistrations
  class EligibilityTraceService
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
          kind = policy_result[:kind]
          next unless kind == PrerequisiteCampaignDecoration::PREREQUISITE_CAMPAIGN_KIND

          policy_result[:config] =
            PrerequisiteCampaignDecoration.decorate_config(policy_result[:config])
        end
      end
  end
end

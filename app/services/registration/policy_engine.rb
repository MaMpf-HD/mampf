module Registration
  class PolicyEngine
    Result = Struct.new(:pass, :failed_policy, :trace, keyword_init: true)

    def initialize(campaign)
      @campaign = campaign
    end

    def eligible?(user, phase: :registration)
      trace = []

      policies_for_phase(phase).each do |policy|
        outcome = policy.evaluate(user)
        trace << outcome

        unless outcome[:pass]
          return Result.new(pass: false,
                            failed_policy: policy,
                            trace: trace)
        end
      end

      Result.new(pass: true, failed_policy: nil, trace: trace)
    end

    private

      attr_reader :campaign

      def policies_for_phase(phase)
        campaign.registration_policies.active.for_phase(phase).order(:position)
      end
  end
end

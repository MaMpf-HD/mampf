module Registration
  # Evaluates the ordered set of policies defined for a campaign.
  # Acts as the decision maker that checks if a user satisfies all constraints
  # (e.g. prerequisites, status) required for a specific phase.
  class PolicyEngine
    Result = Struct.new(:pass, :failed_policy, :trace, keyword_init: true)

    def initialize(campaign)
      @campaign = campaign
    end

    def eligible?(user, phase: :registration)
      trace = []

      policies_for_phase(phase).each do |policy|
        outcome = policy.evaluate(user)
        trace << {
          policy_id: policy.id,
          kind: policy.kind,
          phase: policy.phase,
          outcome: outcome
        }

        unless outcome[:pass]
          return Result.new(
            pass: false,
            failed_policy: policy,
            trace: trace
          )
        end
      end

      Result.new(pass: true, failed_policy: nil, trace: trace)
    end

    def full_trace_for(user, phase: :registration)
      policies_for_phase(phase).map do |policy|
        outcome = policy.evaluate(user)

        {
          policy_id: policy.id,
          kind: policy.kind,
          phase: policy.phase,
          outcome: outcome
        }
      end
    end

    def full_trace_with_config_for(user, phase: :registration)
      policies_for_phase(phase).map do |policy|
        outcome = policy.evaluate(user)

        {
          policy_id: policy.id,
          kind: policy.kind,
          phase: policy.phase,
          config: policy.config,
          outcome: outcome
        }
      end
    end

    private

      attr_reader :campaign

      def policies_for_phase(phase)
        campaign.registration_policies.active.for_phase(phase).order(:position)
      end
  end
end

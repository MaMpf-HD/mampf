module UserRegistrations
  # Reconstructs the failed finalization policies for a completed campaign from
  # the persisted rejection reasons of a user. Unlike EligibilityTraceService,
  # it does NOT re-evaluate the policies against the user's current state, so
  # the displayed rejection reasons stay stable even after the student later
  # fulfils the requirement.
  #
  # Each returned entry mirrors the shape of an EligibilityTraceService entry
  # (kind, phase, config, outcome) so it can be rendered with the same
  # eligibility-failure messaging, or carries a :fallback_label when the
  # originating policy can no longer be identified.
  class FinalizedRejectionTraceService
    def initialize(campaign, user)
      @campaign = campaign
      @user = user
    end

    def call
      policy_rejected_registrations.map do |registration|
        snapshot_for(registration) ||
          { fallback_label: registration.resolved_rejection_reason_label }
      end
    end

    private

      def policy_rejected_registrations
        @campaign.user_registrations
                 .rejected
                 .with_policy_rejection_reason
                 .where(user_id: @user.id)
      end

      def snapshot_for(registration)
        policy = @campaign.registration_policies
                          .for_phase(:finalization)
                          .find_by(id: registration.rejection_policy_id)
        return unless policy

        {
          kind: policy.kind,
          phase: policy.phase,
          config: config_snapshot(policy),
          outcome: {
            pass: false,
            code: registration.rejection_reason_code
          }
        }
      end

      def config_snapshot(policy)
        return policy.config.to_h.deep_dup unless policy.prerequisite_campaign?

        PrerequisiteCampaignDecoration.decorate_config(policy.config)
      end
  end
end

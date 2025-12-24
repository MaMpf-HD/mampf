module Registration
  class FinalizationGuard
    Result = Struct.new(:success?, :error_code, :error_message, :data, keyword_init: true)

    def initialize(campaign)
      @campaign = campaign
    end

    def check(ignore_policies: false)
      if @campaign.completed?
        return failure(:already_completed,
                       I18n.t("registration.allocation.errors.already_completed"))
      end

      # 1. Status Check
      # FCFS must be closed. Preference-based must be processing.
      if @campaign.preference_based?
        unless @campaign.processing?
          return failure(:wrong_status,
                         I18n.t("registration.allocation.errors.wrong_status"))
        end
      else
        unless @campaign.closed?
          return failure(:wrong_status,
                         I18n.t("registration.allocation.errors.wrong_status"))
        end
      end

      # 2. Policy Check
      unless ignore_policies
        policy_errors = check_policies
        if policy_errors.any?
          return failure(:policy_violation,
                         I18n.t("registration.allocation.errors.policy_violation"), policy_errors)
        end
      end

      success
    end

    private

      def check_policies
        # Check policies that apply to finalization phase (or both)
        policies = @campaign.registration_policies.active.for_phase(:finalization)
        return [] if policies.empty?

        invalid_users = []

        @campaign.user_registrations.confirmed.includes(:user).find_each do |registration|
          user = registration.user
          policies.each do |policy|
            result = policy.evaluate(user)
            next if result[:pass]

            invalid_users << { user_id: user.id,
                               registration_id: registration.id,
                               name: user.name,
                               email: user.email,
                               policy: policy.kind }
          end
        end

        invalid_users
      end

      def validate_policies
        # Deprecated: use check_policies instead
        errors = check_policies
        return success if errors.empty?

        failure(:policy_violation,
                I18n.t("registration.allocation.errors.policy_violation"),
                errors)
      end

      def success
        Result.new(success?: true)
      end

      def failure(code, message, data = nil)
        Result.new(success?: false, error_code: code, error_message: message, data: data)
      end
  end
end

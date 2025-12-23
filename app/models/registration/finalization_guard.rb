module Registration
  class FinalizationGuard
    Result = Struct.new(:success?, :error_code, :error_message, :data, keyword_init: true)

    def initialize(campaign)
      @campaign = campaign
    end

    def check
      if @campaign.completed?
        return failure(:already_completed,
                       I18n.t("registration.allocation.errors.already_completed"))
      end

      unless @campaign.processing? || @campaign.closed?
        return failure(:wrong_status,
                       I18n.t("registration.allocation.errors.wrong_status"))
      end

      validate_policies
    end

    private

      def validate_policies
        # Check policies that apply to finalization phase (or both)
        policies = @campaign.registration_policies.active.for_phase(:finalization)
        return success if policies.empty?

        invalid_users = []

        @campaign.user_registrations.confirmed.includes(:user).find_each do |registration|
          user = registration.user
          policies.each do |policy|
            result = policy.evaluate(user)
            next if result[:pass]

            invalid_users << { user_id: user.id,
                               email: user.email,
                               policy: policy.kind }
          end
        end

        if invalid_users.any?
          return failure(:policy_violation,
                         I18n.t("registration.allocation.errors.policy_violation"),
                         invalid_users)
        end

        success
      end

      def success
        Result.new(success?: true)
      end

      def failure(code, message, data = nil)
        Result.new(success?: false, error_code: code, error_message: message, data: data)
      end
  end
end

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
        policies = @campaign.registration_policies
                            .active.for_phase(:finalization)
        return [] if policies.empty?

        registrations = @campaign.user_registrations
                                 .confirmed.includes(:user)
        user_ids = registrations.pluck(:user_id)

        policies.each do |policy|
          policy.handler.batch_prepare(user_ids)
        end

        violations = []

        registrations.find_each do |reg|
          user = reg.user
          policies.each do |policy|
            result = policy.evaluate(user)
            next if result[:pass]

            violations << {
              user_id: user.id,
              registration_id: reg.id,
              name: user.name,
              email: user.email,
              policy: policy.kind,
              policy_config: policy.config,
              evaluate_data: result.except(:pass,
                                           :reason_code,
                                           :message)
            }
          end
        end

        violations
      end

      def success
        Result.new(success?: true)
      end

      def failure(code, message, data = nil)
        Result.new(success?: false, error_code: code, error_message: message, data: data)
      end
  end
end

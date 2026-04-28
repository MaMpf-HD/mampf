module Registration
  class FinalizationGuard
    CLASSIFICATION_PASS = :pass
    CLASSIFICATION_AUTO_REJECT = :auto_reject
    CLASSIFICATION_BLOCKER = :blocker
    CLASSIFICATIONS = [CLASSIFICATION_PASS,
                       CLASSIFICATION_AUTO_REJECT,
                       CLASSIFICATION_BLOCKER].freeze

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

        registrations.find_each.with_object([]) do |reg, violations|
          user = reg.user
          policies.each do |policy|
            outcome = normalized_policy_outcome(policy.evaluate(user))
            next if outcome[:passed]

            violations << {
              user_id: user.id,
              registration_id: reg.id,
              name: user.name,
              email: user.email,
              policy: policy.kind,
              policy_config: policy.config,
              passed: outcome[:passed],
              classification: outcome[:classification],
              reason_code: outcome[:reason_code],
              snapshot: outcome[:snapshot],
              evaluate_data: outcome[:snapshot],
              message: outcome[:message]
            }
          end
        end
      end

      def normalized_policy_outcome(result)
        result = result.to_h.symbolize_keys
        passed = result.fetch(:pass)

        {
          passed: passed,
          classification: normalize_classification(result[:classification], passed),
          reason_code: result[:reason_code] || result[:code],
          snapshot: normalize_snapshot(result),
          message: result[:message]
        }
      end

      def normalize_classification(classification, passed)
        return CLASSIFICATION_PASS if passed

        normalized = classification&.to_sym
        return normalized if CLASSIFICATIONS.include?(normalized)

        CLASSIFICATION_BLOCKER
      end

      def normalize_snapshot(result)
        snapshot = result[:snapshot]
        return snapshot if snapshot.is_a?(Hash)

        details = result[:details]
        return details if details.is_a?(Hash)

        {}
      end

      def success
        Result.new(success?: true)
      end

      def failure(code, message, data = nil)
        Result.new(success?: false, error_code: code, error_message: message, data: data)
      end
  end
end

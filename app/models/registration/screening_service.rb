module Registration
  class ScreeningService
    CLASSIFICATION_PASS = :pass
    CLASSIFICATION_AUTO_REJECT = :auto_reject
    CLASSIFICATION_BLOCKER = :blocker

    BLOCKER_KIND_USER = :user
    BLOCKER_KIND_CONFIGURATION = :configuration

    CLASSIFICATIONS = [CLASSIFICATION_PASS,
                       CLASSIFICATION_AUTO_REJECT,
                       CLASSIFICATION_BLOCKER].freeze
    BLOCKER_KINDS = [BLOCKER_KIND_USER, BLOCKER_KIND_CONFIGURATION].freeze

    Result = Struct.new(:violations, keyword_init: true) do
      def blocker_violations
        Array(violations).select do |violation|
          violation[:classification] == ScreeningService::CLASSIFICATION_BLOCKER
        end
      end

      def auto_reject_violations
        blocked_registration_ids = blocker_violations.map do |violation|
          violation[:registration_id]
        end.uniq

        Array(violations)
          .select do |violation|
            violation[:classification] == ScreeningService::CLASSIFICATION_AUTO_REJECT &&
              !blocked_registration_ids.include?(violation[:registration_id])
          end
          .group_by { |violation| violation[:registration_id] }
          .values
          .map(&:first)
      end

      def blocked?
        blocker_violations.any?
      end
    end

    def initialize(campaign, registrations:)
      @campaign = campaign
      @registrations = registrations
    end

    def call
      policies = @campaign.registration_policies.active.for_phase(:finalization)
      return Result.new(violations: []) if policies.empty?

      registrations = @registrations.includes(:user).to_a
      user_ids = registrations.map(&:user_id).uniq

      policies.each do |policy|
        policy.handler.batch_prepare(user_ids)
      end

      violations = registrations.each_with_object([]) do |registration, result|
        user = registration.user

        policies.each do |policy|
          outcome = normalized_policy_outcome(policy.evaluate(user))
          next if outcome[:passed]

          result << {
            user_id: user.id,
            registration_id: registration.id,
            name: user.name,
            email: user.email,
            policy: policy.kind,
            policy_config: policy.config,
            classification: outcome[:classification],
            blocker_kind: outcome[:blocker_kind],
            reason_type: outcome[:reason_type],
            reason_code: outcome[:reason_code],
            reason_label: outcome[:reason_label],
            message: outcome[:message]
          }
        end
      end

      Result.new(violations: violations)
    end

    private

      def normalized_policy_outcome(result)
        result = result.to_h.symbolize_keys
        passed = result.fetch(:pass)

        {
          passed: passed,
          classification: normalize_classification(result[:classification], passed),
          blocker_kind: normalize_blocker_kind(result[:blocker_kind]),
          reason_type: result[:reason_type],
          reason_code: result[:reason_code] || result[:code],
          reason_label: result[:reason_label] || result[:message],
          message: result[:message]
        }
      end

      def normalize_classification(classification, passed)
        return CLASSIFICATION_PASS if passed

        normalized = classification&.to_sym
        return normalized if CLASSIFICATIONS.include?(normalized)

        CLASSIFICATION_BLOCKER
      end

      def normalize_blocker_kind(blocker_kind)
        normalized = blocker_kind&.to_sym
        return normalized if BLOCKER_KINDS.include?(normalized)

        BLOCKER_KIND_USER
      end
  end
end

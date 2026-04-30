module Registration
  class FinalizationGuard
    Result = Struct.new(:success?, :error_code, :error_message, :data, keyword_init: true) do
      def policy_violations
        Array(data)
      end

      def blocker_violations
        policy_violations.select do |violation|
          violation[:classification] == ScreeningService::CLASSIFICATION_BLOCKER
        end
      end

      def auto_reject_violations
        policy_violations.select do |violation|
          violation[:classification] == ScreeningService::CLASSIFICATION_AUTO_REJECT
        end
      end
    end

    def initialize(campaign)
      @campaign = campaign
    end

    def check
      if @campaign.completed?
        return failure(:already_completed,
                       I18n.t("registration.allocation.errors.already_completed"))
      end

      if @campaign.preference_based?
        unless @campaign.processing? && @campaign.allocation_decided_at.present?
          return failure(:wrong_status,
                         I18n.t("registration.allocation.errors.wrong_status"))
        end

        return success
      end

      unless @campaign.closed?
        return failure(:wrong_status,
                       I18n.t("registration.allocation.errors.wrong_status"))
      end

      screening = Registration::ScreeningService.new(
        @campaign,
        registrations: @campaign.user_registrations.where.not(status: :rejected)
      ).call

      if screening.blocked?
        return failure(:policy_violation,
                       I18n.t("registration.allocation.errors.policy_violation"),
                       screening.violations)
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

# Checks whether the registration campaign can be finalized and performs the necessary checks and screenings.
module Registration
  class FinalizationGuard
    Result = Struct.new(:success?,
                        :error_code,
                        :error_message,
                        :data,
                        :screening_result,
                        keyword_init: true) do
      def initialize(**attributes)
        super(**attributes)

        self.screening_result ||= Registration::ScreeningService::Result.new(
          violations: Array(data)
        )
        self.data = screening_result.violations
      end

      def policy_violations
        screening_result.violations
      end

      def blocker_violations
        screening_result.blocker_violations
      end

      def auto_reject_violations
        screening_result.auto_reject_violations
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
                       screening)
      end

      success(screening)
    end

    def success(screening_result = nil)
      Result.new(success?: true, screening_result: screening_result)
    end

    def failure(code, message, screening_result_or_data = nil)
      screening_result, data = if screening_result_or_data.is_a?(
        Registration::ScreeningService::Result
      )
        [screening_result_or_data, nil]
      else
        [nil, screening_result_or_data]
      end

      Result.new(success?: false,
                 error_code: code,
                 error_message: message,
                 data: data,
                 screening_result: screening_result)
    end
  end
end

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

      # 2. Certification Completeness Check
      # Not overridable by force — all registered students must have
      # a decided (passed/failed) certification before finalization.
      cert_result = check_certification_completeness
      return cert_result if cert_result

      # 3. Policy Check
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

      def check_certification_completeness
        perf_policy = @campaign.registration_policies
                               .active.for_phase(:finalization)
                               .find { |p| p.kind == "student_performance" }
        return nil unless perf_policy

        lecture_id = perf_policy.config&.dig("lecture_id")
        return nil unless lecture_id

        registered_user_ids = @campaign.user_registrations
                                       .confirmed.pluck(:user_id)
        return nil if registered_user_ids.empty?

        decided_user_ids = StudentPerformance::Certification
                           .where(lecture_id: lecture_id,
                                  user_id: registered_user_ids)
                           .where(status: [:passed, :failed])
                           .pluck(:user_id)

        undecided_ids = registered_user_ids - decided_user_ids

        pending_ids = StudentPerformance::Certification
                      .where(lecture_id: lecture_id,
                             user_id: undecided_ids,
                             status: :pending)
                      .pluck(:user_id)

        has_records_ids = StudentPerformance::Record
                          .where(lecture_id: lecture_id,
                                 user_id: undecided_ids)
                          .pluck(:user_id)
        missing_ids = (undecided_ids - pending_ids) & has_records_ids

        blockable_ids = missing_ids + pending_ids
        return nil if blockable_ids.empty?

        users = User.where(id: blockable_ids)
                    .index_by(&:id)

        data = {
          missing: missing_ids.map do |id|
            { user_id: id, name: users[id]&.name,
              email: users[id]&.email }
          end,
          pending: pending_ids.map do |id|
            { user_id: id, name: users[id]&.name,
              email: users[id]&.email }
          end,
          lecture_id: lecture_id
        }

        failure(
          :certification_incomplete,
          I18n.t("registration.allocation.errors.certification_incomplete"),
          data
        )
      end

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

      def success
        Result.new(success?: true)
      end

      def failure(code, message, data = nil)
        Result.new(success?: false, error_code: code, error_message: message, data: data)
      end
  end
end

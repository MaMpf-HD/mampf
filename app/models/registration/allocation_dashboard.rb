module Registration
  class AllocationDashboard
    attr_reader :campaign

    def initialize(campaign)
      @campaign = campaign
    end

    def stats
      @stats ||= begin
        assignment = @campaign.user_registrations
                              .where(status: :confirmed)
                              .pluck(:user_id, :registration_item_id)
                              .to_h
        rejected_user_ids = @campaign.rejected_users.pluck(:id)

        Registration::AllocationStats.new(
          @campaign,
          assignment,
          rejected_user_ids: rejected_user_ids
        )
      end
    end

    def unassigned_students
      @unassigned_students ||= User.where(id: stats.unassigned_user_ids).order(:email)
    end

    def rejected_students
      @rejected_students ||= User.where(id: stats.rejected_user_ids).order(:email)
    end

    def rejection_reasons_for(student)
      Array(rejected_registrations_by_user[student.id])
        .filter_map do |registration|
          Registration::UserRegistration.localized_rejection_reason_label(
            reason_code: registration.rejection_reason_code,
            reason_label: registration.rejection_reason_label
          )
        end
        .uniq
        .join(", ")
    end

    def guard_result
      @guard_result ||= if @campaign.preference_based? && @campaign.allocation_decided_at.blank?
        Registration::ScreeningService.new(
          @campaign,
          registrations: @campaign.user_registrations.where.not(status: :rejected)
        ).call
      else
        Registration::FinalizationGuard.new(@campaign).check
      end
    end

    def blocker_violations
      @blocker_violations ||= guard_result.blocker_violations
    end

    def policy_violations
      blocker_violations
    end

    def finalization_policies
      @finalization_policies ||=
        @campaign.registration_policies.active.for_phase(:finalization)
    end

    def performance_rule
      return @performance_rule if defined?(@performance_rule)

      perf_policy = finalization_policies.find { |p| p.kind == "student_performance" }
      lecture_ids = perf_policy&.lecture_ids || []
      @performance_rule = lecture_ids.present? &&
                          StudentPerformance::Rule
                          .where(lecture_id: lecture_ids, active: true)
                          .includes(rule_achievements: :achievement)
                          .first
    end

    def performance_lecture
      return @performance_lecture if defined?(@performance_lecture)

      perf_policy = finalization_policies.find { |p| p.kind == "student_performance" }
      @performance_lecture = perf_policy&.lecture_ids&.then do |lecture_ids|
        Lecture.find_by(id: lecture_ids)
      end
    end

    def performance_evidence_by_user
      @performance_evidence_by_user ||= build_performance_evidence
    end

    def performance_evidence_for(user_id)
      performance_evidence_by_user[user_id]
    end

    def projected_auto_rejection_count
      return 0 unless @campaign.first_come_first_served?
      return 0 if @campaign.completed?

      @projected_auto_rejection_count ||= guard_result.auto_reject_violations.count
    end

    def allocation_run?
      @campaign.last_allocation_calculated_at.present?
    end

    def demand_per_item
      @demand_per_item ||= calculate_demand_per_item
    end

    def conflicting_registrations
      @conflicting_registrations ||= calculate_conflicts
    end

    private

      def calculate_conflicts
        return [] if @campaign.completed?
        return [] unless @campaign.campaignable.is_a?(Lecture)

        registerable_class = first_registerable_class
        return [] unless registerable_class&.exclusive_assignment?

        registered_user_ids = @campaign.user_registrations.pluck(:user_id)
        return [] if registered_user_ids.empty?

        lecture = @campaign.campaignable
        siblings = lecture.public_send(registerable_class.model_name.plural)

        allocated_map = {}
        siblings.find_each do |sibling|
          (sibling.allocated_user_ids & registered_user_ids).each do |uid|
            allocated_map[uid] = sibling
          end
        end

        return [] if allocated_map.empty?

        registrations_by_user = @campaign.user_registrations
                                         .where(user_id: allocated_map.keys)
                                         .includes(:user)
                                         .index_by(&:user_id)

        allocated_map.map do |uid, registerable|
          {
            user: registrations_by_user[uid]&.user,
            registerable: registerable,
            registration: registrations_by_user[uid]
          }
        end
      end

      def build_performance_evidence
        sp_user_ids = policy_violations
                      .select { |v| v[:policy] == "student_performance" }
                      .map { |v| v[:user_id] }
        return {} if sp_user_ids.empty?

        lecture = performance_lecture
        return {} unless lecture

        certs = StudentPerformance::Certification
                .where(lecture: lecture, user_id: sp_user_ids)
                .includes(:certified_by)
                .index_by(&:user_id)

        records = StudentPerformance::Record
                  .where(lecture: lecture, user_id: sp_user_ids)
                  .index_by(&:user_id)

        rule = performance_rule
        evaluator = rule ? StudentPerformance::Evaluator.new(rule) : nil

        evals_by_user = if evaluator && records.any?
          evaluator.bulk_evaluate(records.values)
                   .transform_keys(&:user_id)
        else
          {}
        end

        sp_user_ids.to_h do |uid|
          [uid, {
            cert: certs[uid],
            record: records[uid],
            rule: rule,
            eval: evals_by_user[uid]
          }]
        end
      end

      def first_registerable_class
        type_name = @campaign.registration_items.pick(:registerable_type)
        type_name&.constantize
      rescue NameError
        nil
      end

      def calculate_demand_per_item
        counts = @campaign.user_registrations
                          .group(:registration_item_id, :preference_rank)
                          .count

        grouped = counts.each_with_object(Hash.new do |h, k|
          h[k] = {}
        end) do |((item_id, rank), cnt), acc|
          acc[item_id][rank] = cnt
        end

        items = @campaign.registration_items
                         .includes(:registerable)
                         .sort_by { |i| i.title.to_s }

        items.map do |item|
          rank_counts = grouped[item.id] || {}
          first  = rank_counts[1] || 0
          second = rank_counts[2] || 0
          third  = rank_counts[3] || 0
          rest   = rank_counts.sum { |r, c| r.is_a?(Integer) && r > 3 ? c : 0 }
          {
            item: item,
            first: first,
            second: second,
            third: third,
            rest: rest,
            total: first + second + third + rest,
            capacity: item.capacity
          }
        end
      end

      def rejected_registrations_by_user
        @rejected_registrations_by_user ||= @campaign.user_registrations
                                                     .where(
                                                       status: :rejected,
                                                       user_id: stats.rejected_user_ids
                                                     )
                                                     .to_a
                                                     .group_by(&:user_id)
      end
  end
end

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
        Registration::AllocationStats.new(@campaign, assignment)
      end
    end

    def unassigned_students
      @unassigned_students ||= User.where(id: stats.unassigned_user_ids).order(:email)
    end

    def guard_result
      @guard_result ||=
        Registration::FinalizationGuard.new(@campaign).check
    end

    def certification_incomplete?
      guard_result.error_code == :certification_incomplete
    end

    def certification_incomplete_data
      return nil unless certification_incomplete?

      guard_result.data
    end

    def policy_violations
      return [] if guard_result.success?
      return [] unless guard_result.error_code == :policy_violation

      guard_result.data || []
    end

    def finalization_policies
      @finalization_policies ||=
        @campaign.registration_policies.active.for_phase(:finalization)
    end

    def performance_rule
      return @performance_rule if defined?(@performance_rule)

      perf_policy = finalization_policies.find { |p| p.kind == "student_performance" }
      lid = perf_policy&.config&.dig("lecture_id")
      @performance_rule = lid &&
                          StudentPerformance::Rule
                          .where(lecture_id: lid, active: true)
                          .includes(rule_achievements: :achievement)
                          .first
    end

    def performance_lecture
      return @performance_lecture if defined?(@performance_lecture)

      perf_policy = finalization_policies.find { |p| p.kind == "student_performance" }
      lid = perf_policy&.config&.dig("lecture_id")
      @performance_lecture = lid && Lecture.find_by(id: lid)
    end

    def violations_by_user
      @violations_by_user ||= policy_violations.group_by { |v| v[:user_id] }
    end

    def violation_counts_by_policy
      @violation_counts_by_policy ||=
        policy_violations
        .group_by { |v| v[:policy] }
        .transform_values(&:size)
    end

    def finalization_policies
      @finalization_policies ||=
        @campaign.registration_policies.active.for_phase(:finalization)
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
  end
end

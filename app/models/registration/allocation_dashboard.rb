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

    def policy_violations
      @policy_violations ||= begin
        guard_result = Registration::FinalizationGuard.new(@campaign).check
        guard_result.success? ? [] : (guard_result.data || [])
      end
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

        registered_user_ids = @campaign.user_registrations.pluck(:user_id)

        existing_memberships =
          TutorialMembership.joins(:tutorial)
                            .where(tutorials: { lecture_id: @campaign.campaignable.id })
                            .where(user_id: registered_user_ids)
                            .includes(:user, :tutorial)

        registrations_by_user = @campaign.user_registrations
                                         .where(user_id: existing_memberships.map(&:user_id))
                                         .index_by(&:user_id)

        existing_memberships.map do |m|
          {
            user: m.user,
            tutorial: m.tutorial,
            registration: registrations_by_user[m.user_id]
          }
        end
      end

      def calculate_demand_per_item
        counts = @campaign.user_registrations
                          .group(:registration_item_id, :preference_rank)
                          .count

        items = @campaign.registration_items
                         .includes(:registerable)
                         .sort_by { |i| i.title.to_s }

        items.map do |item|
          rank_counts = counts.select { |k, _| k[0] == item.id }
                              .transform_keys { |k| k[1] }
          first  = rank_counts[1] || 0
          second = rank_counts[2] || 0
          third  = rank_counts[3] || 0
          rest   = rank_counts.select { |r, _| r.is_a?(Integer) && r > 3 }
                              .values.sum
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

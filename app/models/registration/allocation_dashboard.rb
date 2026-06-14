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
        .filter_map(&:resolved_rejection_reason_label)
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

    def blockers?
      blocker_violations.present?
    end

    def blocker_user_count
      blocker_violations.pluck(:user_id).uniq.size
    end

    def finalization_policies
      @finalization_policies ||=
        @campaign.registration_policies.active.for_phase(:finalization)
    end

    def projected_auto_rejection_count
      return 0 unless @campaign.first_come_first_served?
      return 0 if @campaign.completed?

      @projected_auto_rejection_count ||= guard_result.auto_reject_violations.count
    end

    def projected_auto_rejections?
      projected_auto_rejection_count.positive?
    end

    def current_registration_state?
      @campaign.first_come_first_served? && !@campaign.completed?
    end

    def finalization_status
      return :blocked if blockers?

      :auto_rejections if projected_auto_rejections?
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
        @rejected_registrations_by_user ||= @campaign.open_rejected_registrations
                                                     .where(user_id: stats.rejected_user_ids)
                                                     .to_a
                                                     .group_by(&:user_id)
      end
  end
end

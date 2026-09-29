module Registration
  class AllocationDashboard
    PERFORMANCE_POLICY = "student_performance".freeze
    # Least evidence first: someone with nothing on file is the likeliest to be
    # a mistake, someone who failed the likeliest to be correct.
    PERFORMANCE_STATUS_ORDER = { no_cert: 0, pending: 1, failed: 2 }.freeze

    ViolationReport = Struct.new(:user_count, :policy_counts,
                                 :configuration_blockers, :user_blockers,
                                 :performance_entries, :performance_status_counts,
                                 :additional_blockers, :other_entries,
                                 keyword_init: true)

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

    # All of them, not the first: the policy demands a pass in every lecture it
    # names, so evidence about one of them says nothing about the rest.
    def performance_lectures
      return @performance_lectures if defined?(@performance_lectures)

      perf_policy = finalization_policies.find { |p| p.kind == PERFORMANCE_POLICY }
      @performance_lectures = perf_policy ? Lecture.where(id: perf_policy.lecture_ids).to_a : []
    end

    def violation_report
      @violation_report ||= build_violation_report
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

    def summary_items
      items = [
        {
          kind: :total_registrations,
          count: stats.total_registrations
        }
      ]

      items.concat(
        if current_registration_state?
          current_registration_state_summary_items
        else
          allocation_summary_items
        end
      )

      items
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

      def build_violation_report
        violations = blocker_violations.uniq { |v| [v[:user_id], v[:policy]] }
        grouped = violations.group_by { |v| v[:user_id] }
        performance = performance_violation_entries(grouped)

        ViolationReport.new(
          user_count: grouped.size,
          policy_counts: violations.group_by { |v| v[:policy] }.transform_values(&:size),
          configuration_blockers: violations.any? { |v| configuration_blocker?(v) },
          user_blockers: violations.any? do |v|
            v[:blocker_kind] == Registration::ScreeningService::BLOCKER_KIND_USER
          end,
          performance_entries: performance,
          performance_status_counts: performance.group_by { |e| e[:status_key] }
                                                .transform_values(&:size),
          additional_blockers: performance.any? { |e| e[:other_violations].present? },
          other_entries: other_violation_entries(grouped)
        )
      end

      def performance_violation_entries(grouped)
        certifications = certifications_by_user(grouped.keys)

        entries = grouped.filter_map do |user_id, violations|
          next unless violations.any? { |v| v[:policy] == PERFORMANCE_POLICY }

          {
            user_id: user_id,
            first: violations.first,
            status_key: performance_status_for(certifications[user_id].to_a),
            other_violations: violations.reject { |v| v[:policy] == PERFORMANCE_POLICY },
            can_defer: violations.none? { |v| configuration_blocker?(v) }
          }
        end

        entries.sort_by do |entry|
          [PERFORMANCE_STATUS_ORDER.fetch(entry[:status_key]), entry[:first][:email].to_s]
        end
      end

      def other_violation_entries(grouped)
        entries = grouped.filter_map do |user_id, violations|
          next if violations.any? { |v| v[:policy] == PERFORMANCE_POLICY }

          {
            user_id: user_id,
            first: violations.first,
            violations: violations,
            can_defer: violations.none? { |v| configuration_blocker?(v) }
          }
        end

        entries.sort_by { |entry| entry[:first][:email].to_s }
      end

      def certifications_by_user(user_ids)
        StudentPerformance::Certification
          .where(lecture_id: performance_lectures.map(&:id), user_id: user_ids)
          .group_by(&:user_id)
      end

      # What the handler blocked on: the lectures still without a pass. A pass
      # elsewhere in the list cannot speak for them.
      def performance_status_for(certifications)
        passed_ids = certifications.select(&:passed?).map(&:lecture_id)
        outstanding_ids = performance_lectures.map(&:id) - passed_ids
        statuses = certifications.select { |c| outstanding_ids.include?(c.lecture_id) }
                                 .map { |c| c.status.to_sym }

        return :failed if statuses.include?(:failed)
        return :pending if statuses.include?(:pending)

        :no_cert
      end

      def configuration_blocker?(violation)
        violation[:blocker_kind] ==
          Registration::ScreeningService::BLOCKER_KIND_CONFIGURATION
      end

      def current_registration_state_summary_items
        items = [
          {
            kind: :currently_confirmed,
            count: stats.assigned_users
          }
        ]

        if stats.rejected_users.positive?
          items << {
            kind: :currently_rejected,
            count: stats.rejected_users
          }
        end

        items
      end

      def allocation_summary_items
        items = [
          {
            kind: :eligible,
            count: stats.eligible_users
          },
          {
            kind: :assigned,
            count: stats.assigned_users,
            percentage: stats.assigned_percentage
          }
        ]

        if stats.rejected_users.positive?
          items << {
            kind: :rejected,
            count: stats.rejected_users
          }
        end

        items << {
          kind: :unassigned,
          count: stats.unassigned_users
        }

        items
      end

      def calculate_conflicts
        return [] if @campaign.completed?
        return [] unless @campaign.campaignable.is_a?(Lecture)

        classes = displacing_registerable_classes
        return [] if classes.empty?

        registered_user_ids = @campaign.user_registrations.pluck(:user_id)
        return [] if registered_user_ids.empty?

        allocated_map = {}
        classes.each do |registerable_class|
          siblings(registerable_class).find_each do |sibling|
            (sibling.allocated_user_ids & registered_user_ids).each do |uid|
              allocated_map[uid] = sibling
            end
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

      # Every type in the campaign, not one picked at random: a campaign holding
      # both tutorials and talks would otherwise have half its conflicts
      # scanned, or none, depending on which row came back first.
      def displacing_registerable_classes
        @campaign.registration_items
                 .distinct
                 .pluck(:registerable_type)
                 .filter_map do |type_name|
          klass = type_name&.safe_constantize
          next unless klass.respond_to?(:displaces_sibling_assignment?)
          next unless klass.displaces_sibling_assignment?

          klass
        end
      end

      # A registerable the lecture has no association for cannot have siblings
      # to displace.
      def siblings(registerable_class)
        association = registerable_class.model_name.plural
        lecture = @campaign.campaignable
        return registerable_class.none unless lecture.respond_to?(association)

        lecture.public_send(association)
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

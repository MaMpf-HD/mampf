module Registration
  class AllocationService
    class BlockedError < StandardError
      attr_reader :screening_result

      def initialize(screening_result)
        @screening_result = screening_result
        super("Allocation blocked by policy violations")
      end
    end

    def initialize(campaign, strategy: :min_cost_flow, **opts)
      @campaign = campaign
      @strategy = strategy
      @opts = opts
    end

    # Runs the allocation algorithm and saves results.
    #
    # Locks all registerables (tutorials/talks/cohorts) during solver execution to prevent
    # capacity modifications that would invalidate the computed allocation. Without this lock,
    # concurrent capacity edits via tutorial/talk/cohort controllers could cause the solver
    # results to be based on stale data.
    #
    # Philosophy: "Hands off while the solver is running" - capacity edits are blocked for
    # the brief window (~1 second) when allocation is being computed to ensure data consistency.
    #
    # Note: Row-level locks are automatically released when the transaction commits or rolls back.
    def allocate!
      unless @campaign.preference_based?
        raise(ArgumentError,
              "Allocation can only be triggered for preference-based campaigns. " \
              "As a user, you should never see this error, please contact the MaMpf team.")
      end

      Registration::Campaign.transaction do
        # Lock campaign to prevent concurrent allocate! calls
        @campaign.lock!

        # Lock all registerables to prevent capacity changes during solver run
        # These locks will be held for ~1 second and automatically released on commit/rollback
        @campaign.registration_items.includes(:registerable).find_each do |item|
          item.registerable.lock!
        end

        prepare_for_allocation!

        screening = Registration::ScreeningService.new(
          @campaign,
          registrations: active_registrations
        ).call

        raise(BlockedError, screening) if screening.blocked?

        apply_auto_rejections!(screening)

        solver =
          case @strategy
          when :min_cost_flow
            Registration::Solvers::MinCostFlow.new(@campaign, **@opts)
          else
            raise(ArgumentError, "Unknown strategy '#{@strategy}'")
          end

        result = solver.run
        save_allocation(result)
      end
    end

    private

      def save_allocation(allocation)
        Registration::Campaign.transaction do
          process_allocations(allocation)
          update_item_counts
          update_campaign_status
        end
      end

      def prepare_for_allocation!
        subquery = Registration::UserRegistration
                   .select(:user_id)
                   .where(registration_campaign_id: @campaign.id)
                   .group(:user_id)
                   .having("count(*) > 1")

        @campaign.user_registrations
                 .where(preference_rank: nil)
                 .where(user_id: subquery)
                 .delete_all

        # rubocop:disable Rails/SkipsModelValidations
        @campaign.user_registrations
                 .where(status: [:pending, :confirmed])
                 .update_all(
                   status: :pending,
                   rejection_reason_type: nil,
                   rejection_reason_code: nil,
                   rejection_reason_label: nil,
                   rejected_at: nil,
                   updated_at: Time.current
                 )
        @campaign.user_registrations
                 .where(status: :rejected)
                 .where.not(
                   rejection_reason_type: Registration::UserRegistration::REJECTION_REASON_TYPE_MANUAL
                 )
                 .update_all(
                   rejection_reason_type: nil,
                   rejection_reason_code: nil,
                   rejection_reason_label: nil,
                   rejected_at: nil,
                   updated_at: Time.current
                 )
        @campaign.update_columns(allocation_decided_at: nil)
        # rubocop:enable Rails/SkipsModelValidations
      end

      def active_registrations
        @campaign.user_registrations.where.not(status: :rejected)
      end

      def apply_auto_rejections!(screening)
        now = Time.current

        screening.auto_reject_violations.each do |violation|
          registration = @campaign.user_registrations.find(violation[:registration_id])
          registration.reject!(
            reason_type: violation[:reason_type] || Registration::UserRegistration::REJECTION_REASON_TYPE_POLICY,
            reason_code: violation[:reason_code].to_s,
            reason_label: violation[:reason_label] || violation[:message],
            rejected_at: now
          )
        end
      end

      def process_allocations(allocation)
        # Group allocations by item_id to perform bulk updates
        allocations_by_item = Hash.new { |h, k| h[k] = [] }
        allocation.each do |user_id, item_id|
          allocations_by_item[item_id] << user_id
        end

        allocations_by_item.each do |item_id, user_ids|
          update_existing_registrations(item_id, user_ids)
          create_forced_assignments(item_id, user_ids)
        end
      end

      def update_existing_registrations(item_id, user_ids)
        # Update existing registrations
        # rubocop:disable Rails/SkipsModelValidations
        @campaign.user_registrations
                 .where(registration_item_id: item_id, user_id: user_ids)
                 .update_all(status: :confirmed, updated_at: Time.current)
        # rubocop:enable Rails/SkipsModelValidations
      end

      def create_forced_assignments(item_id, user_ids)
        # Handle forced assignments: create records for users who didn't select this item
        existing_user_ids = @campaign.user_registrations
                                     .where(registration_item_id: item_id, user_id: user_ids)
                                     .pluck(:user_id)

        missing_user_ids = user_ids - existing_user_ids
        return if missing_user_ids.empty?

        records = missing_user_ids.map do |user_id|
          {
            user_id: user_id,
            registration_item_id: item_id,
            registration_campaign_id: @campaign.id,
            status: Registration::UserRegistration.statuses[:confirmed],
            preference_rank: nil,
            created_at: Time.current,
            updated_at: Time.current
          }
        end

        # rubocop:disable Rails/SkipsModelValidations
        Registration::UserRegistration.insert_all(records)
        # rubocop:enable Rails/SkipsModelValidations
      end

      def update_item_counts
        # Recalculate confirmed_registrations_count for all items in the campaign
        # This is necessary because we used update_all/delete_all/insert_all which skip callbacks
        @campaign.registration_items.each do |item|
          count = item.user_registrations.confirmed.count
          # rubocop:disable Rails/SkipsModelValidations
          item.update_columns(confirmed_registrations_count: count)
          # rubocop:enable Rails/SkipsModelValidations
        end
      end

      def update_campaign_status
        @campaign.touch(:last_allocation_calculated_at)
        @campaign.update!(status: :processing,
                          allocation_decided_at: Time.current)
      end
  end
end

module Registration
  class AllocationService
    def initialize(campaign, strategy: :min_cost_flow, **opts)
      @campaign = campaign
      @strategy = strategy
      @opts = opts
    end

    def allocate!
      # Clean up forced registrations from previous runs (idempotency)
      # Only delete rank-less registrations if the user has other registrations,
      # preserving manual single-assignments.
      subquery = Registration::UserRegistration
                 .select(:user_id)
                 .where(registration_campaign_id: @campaign.id)
                 .group(:user_id)
                 .having("count(*) > 1")

      @campaign.user_registrations
               .where(preference_rank: nil)
               .where(user_id: subquery)
               .delete_all

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

    private

      def save_allocation(allocation)
        Registration::Campaign.transaction do
          # Reset all registrations to pending to clear previous runs
          # This ensures idempotency if we run the solver multiple times.
          # rubocop:disable Rails/SkipsModelValidations
          @campaign.user_registrations.update_all(status: :pending, updated_at: Time.current)
          # rubocop:enable Rails/SkipsModelValidations

          # Group allocations by item_id to perform bulk updates
          allocations_by_item = Hash.new { |h, k| h[k] = [] }
          allocation.each do |user_id, item_id|
            allocations_by_item[item_id] << user_id
          end

          allocations_by_item.each do |item_id, user_ids|
            # Update existing registrations
            # rubocop:disable Rails/SkipsModelValidations
            @campaign.user_registrations
                     .where(registration_item_id: item_id, user_id: user_ids)
                     .update_all(status: :confirmed, updated_at: Time.current)
            # rubocop:enable Rails/SkipsModelValidations

            # Handle forced assignments: create records for users who didn't select this item
            existing_user_ids = @campaign.user_registrations
                                         .where(registration_item_id: item_id, user_id: user_ids)
                                         .pluck(:user_id)

            missing_user_ids = user_ids - existing_user_ids
            next if missing_user_ids.empty?

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

          # Ensure campaign is in processing state (Allocation Run)
          @campaign.update!(status: :processing) unless @campaign.processing?
        end
      end
  end
end

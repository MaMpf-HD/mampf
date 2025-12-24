module Registration
  class AllocationService
    def initialize(campaign, strategy: :min_cost_flow, **opts)
      @campaign = campaign
      @strategy = strategy
      @opts = opts
    end

    def allocate!
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
          @campaign.user_registrations.update_all(status: :pending) # rubocop:disable Rails/SkipsModelValidations

          # Mark selected registrations as confirmed
          # allocation is a Hash: { user_id => registration_item_id }
          allocation.each do |user_id, item_id|
            @campaign.user_registrations
                     .where(user_id: user_id, registration_item_id: item_id)
                     .update_all(status: :confirmed) # rubocop:disable Rails/SkipsModelValidations
          end

          # Ensure campaign is in processing state (Allocation Run)
          @campaign.update!(status: :processing) unless @campaign.processing?
        end
      end
  end
end

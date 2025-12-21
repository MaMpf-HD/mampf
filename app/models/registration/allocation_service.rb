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
          raise(ArgumentError, "Unknown strategy #{@strategy}")
        end
      solver.run
    end
  end
end

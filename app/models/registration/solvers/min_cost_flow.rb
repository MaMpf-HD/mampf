require "or_tools"

module Registration
  module Solvers
    class MinCostFlow
      # Penalty for unassigned users (must be higher than any possible preference cost)
      BIG_PENALTY = 1_000_000

      # @param campaign [Registration::Campaign]
      # @param allow_unassigned [Boolean] If true, adds a dummy node to absorb overflow
      def initialize(campaign, allow_unassigned: true)
        @campaign = campaign
        @allow_unassigned = allow_unassigned

        # Load data
        # Fetch all registrations (preferences) for this campaign
        @registrations = campaign.user_registrations.includes(:user)

        # Identify unique users involved in the campaign
        @user_ids = @registrations.map(&:user_id).uniq
        @items = campaign.registration_items.includes(:registerable)

        # Map IDs to 0..N indices for the solver
        @user_to_idx = @user_ids.each_with_index.to_h
        @item_to_idx = @items.map(&:id).each_with_index.to_h
      end

      def run
        return {} if @user_ids.empty?

        build_and_solve
      end

      private

        def build_and_solve
          mcf = ORTools::SimpleMinCostFlow.new

          # Node Indices
          source = 0
          user_offset = 1
          item_offset = user_offset + @user_ids.size
          sink_real = item_offset + @items.size
          dummy_node = sink_real + 1
          sink_final = @allow_unassigned ? dummy_node + 1 : sink_real

          # 1. Supply / Demand
          # Source produces flow equal to number of users
          mcf.set_node_supply(source, @user_ids.size)
          # Sink consumes flow equal to number of users
          mcf.set_node_supply(sink_final, -@user_ids.size)

          # 2. Edges: Source -> Users
          @user_ids.each_with_index do |_, i|
            mcf.add_arc_with_capacity_and_unit_cost(source, user_offset + i, 1, 0)
          end

          # 3. Edges: Users -> Items (Preferences)
          # Group registrations by user to process their choices
          regs_by_user = @registrations.group_by(&:user_id)

          regs_by_user.each do |user_id, user_regs|
            u_idx = @user_to_idx[user_id]
            next unless u_idx

            user_regs.each do |reg|
              i_idx = @item_to_idx[reg.registration_item_id]
              next unless i_idx # Skip if item not found in current set

              # Cost is based on preference_rank.
              # We assume rank 1 is best.
              # Using rank directly as cost (Linear).
              # If geometric priority is needed, use 10**(rank-1).
              rank = reg.preference_rank || 999
              cost = rank

              mcf.add_arc_with_capacity_and_unit_cost(
                user_offset + u_idx,
                item_offset + i_idx,
                1,
                cost
              )
            end
          end

          # 4. Edges: Items -> Sink
          @items.each_with_index do |item, i|
            # nil capacity means unlimited (total supply)
            cap = item.capacity.nil? ? @user_ids.size : [item.capacity.to_i, 0].max

            # Items flow into the final sink (or real sink if we had one)
            # Here we connect directly to sink_final for simplicity unless we need
            # the dummy structure
            target = @allow_unassigned ? sink_real : sink_final

            mcf.add_arc_with_capacity_and_unit_cost(
              item_offset + i,
              target,
              cap,
              0
            )
          end

          # 5. Edges: Dummy Node (Unassigned)
          if @allow_unassigned
            # Users -> Dummy (High Cost)
            @user_ids.each_with_index do |_, i|
              mcf.add_arc_with_capacity_and_unit_cost(
                user_offset + i,
                dummy_node,
                1,
                BIG_PENALTY
              )
            end

            # Dummy -> SinkFinal
            mcf.add_arc_with_capacity_and_unit_cost(
              dummy_node,
              sink_final,
              @user_ids.size,
              0
            )

            # SinkReal -> SinkFinal (Pass-through for assigned flow)
            mcf.add_arc_with_capacity_and_unit_cost(
              sink_real,
              sink_final,
              @user_ids.size,
              0
            )
          end

          status = mcf.solve

          if status == ORTools::SimpleMinCostFlow::OPTIMAL
            extract_solution(mcf, user_offset, item_offset)
          else
            Rails.logger.error("MinCostFlow solver failed with status: #{status}")
            {}
          end
        end

        def extract_solution(mcf, user_offset, item_offset)
          allocation = {}

          # Iterate over all arcs to find active assignments
          mcf.num_arcs.times do |arc|
            next unless mcf.flow(arc).positive?

            tail = mcf.tail(arc)
            head = mcf.head(arc)

            # Check if this arc is User -> Item
            next unless tail >= user_offset && tail < item_offset &&
                        head >= item_offset && head < item_offset + @items.size

            u_idx = tail - user_offset
            i_idx = head - item_offset

            user_id = @user_ids[u_idx]
            item_id = @items[i_idx].id

            allocation[user_id] = item_id
          end

          allocation
        end
    end
  end
end

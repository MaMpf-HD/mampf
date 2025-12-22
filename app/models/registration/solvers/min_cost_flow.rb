require "or-tools"

module Registration
  module Solvers
    class MinCostFlow
      # Cost for leaving a user unassigned (must be higher than any possible preference cost)
      UNASSIGNED_COST = 1_000_000
      # Cost for assigning a user to an item they didn't select (when force_assignments: true)
      FORCED_COST = 5_000

      # @param campaign [Registration::Campaign]
      # @param force_assignments [Boolean] If true, adds high-cost edges to non-selected items,
      #   allowing users to be assigned to items they didn't choose if necessary.
      #   If false, users can only be assigned to their preferences or remain unassigned.
      #   Note: The unassigned path (dummy node) is always available as a last resort.
      def initialize(campaign, force_assignments: true)
        @campaign = campaign
        @force_assignments = force_assignments

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
          sink_final = dummy_node + 1

          # Supply / Demand
          # Source produces flow equal to number of users
          mcf.set_node_supply(source, @user_ids.size)
          # Sink has demand equal to number of users
          mcf.set_node_supply(sink_final, -@user_ids.size)

          # Edges: Source -> Users
          @user_ids.each_with_index do |_, i|
            mcf.add_arc_with_capacity_and_unit_cost(source, user_offset + i, 1, 0)
          end

          # Edges: Users -> Items (Preferences & Forced)
          # Pre-load preferences: user_id -> { item_id -> rank }
          user_prefs = @registrations.group_by(&:user_id).transform_values do |regs|
            regs.to_h { |r| [r.registration_item_id, r.preference_rank] }
          end

          @user_ids.each_with_index do |user_id, u_idx|
            prefs = user_prefs[user_id] || {}

            @items.each_with_index do |item, i_idx|
              rank = prefs[item.id]

              if rank
                # Preference edge
                mcf.add_arc_with_capacity_and_unit_cost(
                  user_offset + u_idx,
                  item_offset + i_idx,
                  1,
                  rank
                )
              elsif @force_assignments
                # Forced assignment edge (only if unassigned is NOT allowed)
                mcf.add_arc_with_capacity_and_unit_cost(
                  user_offset + u_idx,
                  item_offset + i_idx,
                  1,
                  FORCED_COST
                )
              end
            end
          end

          # Edges: Items -> Sink
          @items.each_with_index do |item, i|
            # nil capacity means unlimited (modeled as total user count, since
            # flow cannot exceed supply)
            cap = item.capacity.nil? ? @user_ids.size : [item.capacity.to_i, 0].max

            # Items flow into the real sink
            mcf.add_arc_with_capacity_and_unit_cost(
              item_offset + i,
              sink_real,
              cap,
              0
            )
          end

          # Edges: Dummy Node (Unassigned)
          # Always allow unassigned path as a fallback (with high penalty)
          # Users -> Dummy (High Cost)
          @user_ids.each_with_index do |_, i|
            mcf.add_arc_with_capacity_and_unit_cost(
              user_offset + i,
              dummy_node,
              1,
              UNASSIGNED_COST
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

          status = mcf.solve

          if status == :optimal
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

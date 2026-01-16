module Registration
  class AllocationStats
    def initialize(campaign, assignment)
      @campaign = campaign
      @assignment = assignment
    end

    def calculate
      user_preferences = @campaign.user_registrations
                                  .includes(:registration_item)
                                  .order(:preference_rank)
                                  .group_by(&:user_id)
                                  .transform_values do |regs|
        regs.map(&:registration_item_id)
      end

      stats = initialize_stats(user_preferences.keys.size)

      @assignment.each do |user_id, item_id|
        process_assignment(user_id, item_id, user_preferences, stats)
      end

      calculate_averages(stats)
      calculate_global_metrics(stats)
      stats
    end

    private

      def initialize_stats(total_users)
        {
          total_users: total_users,
          assigned_users: @assignment.size,
          unassigned_users: total_users - @assignment.size,
          preference_counts: Hash.new(0),
          items: {}
        }
      end

      def process_assignment(user_id, item_id, user_preferences, stats)
        prefs = user_preferences[user_id] || []
        rank_index = prefs.index(item_id)
        rank = rank_index ? rank_index + 1 : :forced

        stats[:preference_counts][rank] += 1
        update_item_stats(stats, item_id, rank)
      end

      def update_item_stats(stats, item_id, rank)
        stats[:items][item_id] ||= { count: 0, sum_rank: 0, forced: 0 }
        stats[:items][item_id][:count] += 1

        if rank == :forced
          stats[:items][item_id][:forced] += 1
        else
          stats[:items][item_id][:sum_rank] += rank
        end
      end

      def calculate_averages(stats)
        stats[:items].each_value do |data|
          valid_ranks = data[:count] - data[:forced]
          data[:avg_rank] = if valid_ranks.positive?
            (data[:sum_rank].to_f / valid_ranks).round(2)
          else
            0
          end
          data.delete(:sum_rank)
        end
      end

      def calculate_global_metrics(stats)
        assigned = stats[:assigned_users]
        return if assigned.zero?

        # Global Average Rank (lower is better)
        # We exclude forced assignments from the average to avoid skewing
        sum_rank = stats[:preference_counts].sum do |rank, count|
          rank == :forced ? 0 : rank * count
        end

        non_forced = assigned - (stats[:preference_counts][:forced] || 0)

        stats[:global_avg_rank] = if non_forced.positive?
          (sum_rank.to_f / non_forced).round(2)
        else
          0
        end

        # Percent Top Choice
        top_choice_count = stats[:preference_counts][1] || 0
        stats[:percent_top_choice] = (top_choice_count.to_f / assigned * 100).round(2)
      end
  end
end

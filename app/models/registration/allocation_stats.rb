module Registration
  class AllocationStats
    attr_reader :total_registrations, :assigned_users, :unassigned_users,
                :global_avg_rank, :percent_top_choice, :preference_counts, :items,
                :unassigned_user_ids

    def initialize(campaign, assignment)
      @campaign = campaign
      @assignment = assignment
      calculate
    end

    def assigned_percentage
      return 0 if total_registrations.zero?

      (assigned_users.to_f / total_registrations * 100)
    end

    def unassigned_percentage
      return 0 if total_registrations.zero?

      (unassigned_users.to_f / total_registrations * 100)
    end

    def item_stats
      @campaign.registration_items.includes(:registerable).map do |item|
        stats = @items[item.id] || { count: 0 }
        capacity = item.capacity
        {
          item: item,
          count: stats[:count],
          capacity: capacity,
          percentage: capacity.present? && capacity.positive? ? (stats[:count].to_f / capacity * 100) : nil
        }
      end.sort_by { |data| data[:item].title }
    end

    private

      def calculate
        user_preferences = @campaign.user_registrations
                                    .where.not(preference_rank: nil)
                                    .includes(:registration_item)
                                    .order(:preference_rank)
                                    .group_by(&:user_id)
                                    .transform_values do |regs|
          regs.map(&:registration_item_id)
        end

        @total_registrations = user_preferences.keys.size
        @assigned_users = @assignment.size
        @unassigned_users = @total_registrations - @assigned_users
        @unassigned_user_ids = user_preferences.keys - @assignment.keys
        @preference_counts = Hash.new(0)
        @items = {}
        @global_avg_rank = 0
        @percent_top_choice = 0

        @assignment.each do |user_id, item_id|
          process_assignment(user_id, item_id, user_preferences)
        end

        calculate_averages
        calculate_global_metrics
      end

      def process_assignment(user_id, item_id, user_preferences)
        prefs = user_preferences[user_id] || []
        rank_index = prefs.index(item_id)
        rank = rank_index ? rank_index + 1 : :forced

        @preference_counts[rank] += 1
        update_item_stats(item_id, rank)
      end

      def update_item_stats(item_id, rank)
        @items[item_id] ||= { count: 0, sum_rank: 0, forced: 0 }
        @items[item_id][:count] += 1

        if rank == :forced
          @items[item_id][:forced] += 1
        else
          @items[item_id][:sum_rank] += rank
        end
      end

      def calculate_averages
        @items.each_value do |data|
          valid_ranks = data[:count] - data[:forced]
          data[:avg_rank] = if valid_ranks.positive?
            (data[:sum_rank].to_f / valid_ranks).round(2)
          else
            0
          end
          data.delete(:sum_rank)
        end
      end

      def calculate_global_metrics
        return if @assigned_users.zero?

        # Global Average Rank (lower is better)
        # We exclude forced assignments from the average to avoid skewing
        sum_rank = @preference_counts.sum do |rank, count|
          rank == :forced ? 0 : rank * count
        end

        non_forced = @assigned_users - (@preference_counts[:forced] || 0)

        @global_avg_rank = if non_forced.positive?
          (sum_rank.to_f / non_forced).round(2)
        else
          0
        end

        # Percent Top Choice
        top_choice_count = @preference_counts[1] || 0
        @percent_top_choice = (top_choice_count.to_f / @assigned_users * 100).round(2)
      end
  end
end

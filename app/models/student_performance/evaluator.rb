module StudentPerformance
  class Evaluator
    Result = Struct.new(:proposed_status, :details, keyword_init: true)

    attr_reader :rule

    def initialize(rule)
      @rule = rule
    end

    def evaluate(record)
      return Result.new(proposed_status: :failed, details: {}) unless record

      meets_points = points_met?(record)
      achievement_status = achievements_status(record)

      proposed = if achievement_status == :ungraded
        :inconclusive
      elsif meets_points && achievement_status == :met
        :passed
      else
        :failed
      end

      Result.new(
        proposed_status: proposed,
        details: {
          meets_points: meets_points,
          meets_achievements: achievement_status == :met,
          achievements_ungraded: achievement_status == :ungraded,
          points_total: record.points_total_materialized,
          points_max: record.points_max_materialized,
          percentage: record.percentage_materialized,
          required_points: required_points_threshold,
          required_percentage: rule.min_percentage,
          achievement_ids_met: record.achievements_met_ids,
          achievement_ids_ungraded: Array(record.achievements_ungraded_ids),
          achievement_ids_required: required_achievement_ids
        }
      )
    end

    def bulk_evaluate(records)
      records.index_with { |record| evaluate(record) }
    end

    private

      def points_met?(record)
        if rule.min_points_absolute.present?
          (record.points_total_materialized || 0) >= rule.min_points_absolute
        elsif rule.min_percentage.present?
          (record.percentage_materialized || 0) >= rule.min_percentage
        else
          true
        end
      end

      def achievements_status(record)
        return :met if required_achievement_ids.empty?

        have = Array(record.achievements_met_ids).map(&:to_i).to_set
        need = required_achievement_ids.to_set
        return :met if have >= need

        ungraded = Array(record.achievements_ungraded_ids)
                   .map(&:to_i).to_set
        missing = need - have
        return :ungraded if missing.any? { |id| ungraded.include?(id) }

        :not_met
      end

      def required_achievement_ids
        @required_achievement_ids ||= rule.required_achievements.pluck(:id)
      end

      def required_points_threshold
        rule.min_points_absolute
      end
  end
end

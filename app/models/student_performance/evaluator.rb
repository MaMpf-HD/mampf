module StudentPerformance
  class Evaluator
    # Criteria that are open rather than missed: nobody can be judged on them yet.
    UNDECIDED = [:pending, :ungraded, :not_measurable].freeze

    POINTS_DEFERRALS = [:points_pending, :points_not_measurable].freeze

    DEFERRAL_REASONS = (POINTS_DEFERRALS + [:achievements_ungraded]).freeze

    Result = Struct.new(:proposed_status, :details, keyword_init: true) do
      def verdict_deferral_reasons
        return [] unless proposed_status == :inconclusive

        DEFERRAL_REASONS.select { |reason| details[reason] }
      end

      def points_criterion_deferral
        POINTS_DEFERRALS.find { |reason| details[reason] }
      end
    end

    attr_reader :rule

    # `rule` is a `Rule` or the duck-typed `PreviewRule`: anything answering
    # `min_percentage`, `min_points_absolute` — at most one of them set — and
    # `required_achievements`. The threshold mode is deliberately not part of
    # that contract, since the preview has none.
    def initialize(rule)
      @rule = rule
    end

    def evaluate(record)
      # Not `failed`: no record is the absence of evidence, not evidence of
      # failure, and quietly refusing someone their exam is the worse mistake.
      raise(ArgumentError, "no performance record to evaluate") unless record

      points = points_status(record)
      achievements = achievements_status(record)

      Result.new(
        proposed_status: propose(points, achievements),
        details: {
          meets_points: points == :met,
          points_pending: points == :pending,
          points_not_measurable: points == :not_measurable,
          meets_achievements: achievements == :met,
          achievements_ungraded: achievements == :ungraded
        }
      )
    end

    def bulk_evaluate(records)
      records.index_with { |record| evaluate(record) }
    end

    private

      # A criterion nobody can satisfy any more settles the case; one that is
      # merely unfinished defers it.
      def propose(*statuses)
        return :failed if statuses.include?(:not_met)
        return :inconclusive if statuses.intersect?(UNDECIDED)

        :passed
      end

      def points_status(record)
        return :met if points_met?(record)
        return :not_measurable if points_max_zero?(record)
        return :pending if points_still_reachable?(record)

        :not_met
      end

      # A share of nothing is not a shortfall. A student exempt from every
      # assignment, or a lecture that has none yet, cannot be judged on points —
      # that is for a person to decide, not for a threshold.
      def points_max_zero?(record)
        (record.points_max_materialized || 0).zero?
      end

      def points_met?(record)
        if rule.min_points_absolute.present?
          (record.points_total_materialized || 0) >= rule.min_points_absolute
        elsif rule.min_percentage.present?
          (record.percentage_materialized || 0) >= rule.min_percentage
        else
          true
        end
      end

      # Refusing eligibility because a tutor is behind would be the record's
      # fault, not the student's. Marking can only add points, and the sheets
      # awaiting it are already counted in the maximum, so the best case is
      # simply everything outstanding awarded in full.
      def points_still_reachable?(record)
        pending = record.points_max_pending_materialized || 0
        return false if pending.zero?

        best_total = (record.points_total_materialized || 0) + pending

        if rule.min_points_absolute.present?
          best_total >= rule.min_points_absolute
        elsif rule.min_percentage.present?
          max = record.points_max_materialized || 0
          max.positive? && (best_total / max * 100) >= rule.min_percentage
        else
          false
        end
      end

      def achievements_status(record)
        return :met if required_achievement_ids.empty?

        have = Array(record.achievements_met_ids).to_set(&:to_i)
        need = required_achievement_ids.to_set
        return :met if have >= need

        ungraded = Array(record.achievements_ungraded_ids).to_set(&:to_i)
        missing = need - have
        return :ungraded if missing.any? { |id| ungraded.include?(id) }

        :not_met
      end

      def required_achievement_ids
        @required_achievement_ids ||= rule.required_achievements.pluck(:id)
      end
  end
end

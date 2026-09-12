module StudentPerformance
  class Evaluator
    # Criteria that are open rather than missed: nobody can be judged on them yet.
    UNDECIDED = [:pending, :ungraded, :not_measurable].freeze

    POINTS_DEFERRALS = [:points_not_due, :points_pending,
                        :points_not_measurable].freeze

    DEFERRAL_REASONS = ([:assignments_incomplete] + POINTS_DEFERRALS +
                        [:achievements_ungraded]).freeze

    Result = Struct.new(:proposed_status, :details, keyword_init: true) do
      def verdict_deferral_reasons
        return [] unless proposed_status == :inconclusive
        return [:assignments_incomplete] if details[:assignments_incomplete]

        DEFERRAL_REASONS.select { |reason| details[reason] }
      end

      def points_criterion_deferral
        POINTS_DEFERRALS.find { |reason| details[reason] }
      end

      # The criteria a failed proposal failed on. A criterion that is merely
      # open is not among them: it did not settle the case, the other one did.
      def missed_criteria
        return [] unless proposed_status == :failed

        missed = []
        missed << points_criterion if !details[:meets_points] &&
                                      points_criterion_deferral.nil?
        missed << :achievements if !details[:meets_achievements] && !details[:achievements_ungraded]
        missed
      end

      # A threshold is only ever called missed once it cannot be met any more:
      # while anything is still open the case is deferred, not failed. Where
      # something *is* still open and would not be enough, the stronger
      # sentence is the fair one - it says the student cannot make it up, not
      # that they have not made it yet.
      def points_criterion
        details[:points_outstanding] ? :points_out_of_reach : :points
      end
    end

    attr_reader :rule

    # PreviewRule provides min_percentage and min_points_absolute, no
    # threshold_mode. Require assignments_complete and current due_points so
    # decisions account for assignments being created and points still reachable.
    def initialize(rule, assignments_complete:, due_points:)
      @rule = rule
      @assignments_complete = assignments_complete
      @due_points = due_points
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
          assignments_incomplete: !@assignments_complete,
          meets_points: points == :met,
          points_not_due: points == :pending && not_yet_due(record).positive?,
          points_pending: points == :pending && awaiting_marking(record).positive?,
          points_not_measurable: points == :not_measurable,
          points_outstanding: outstanding_points(record).positive?,
          meets_achievements: achievements == :met,
          achievements_ungraded: achievements == :ungraded
        }.merge(deferral_amounts(record))
      )
    end

    def bulk_evaluate(records)
      records.index_with { |record| evaluate(record) }
    end

    private

      # How many sheets each of the two open points reasons is about, so that
      # the page can say it rather than leaving "not due yet" to stand for
      # anything between one sheet and the rest of the term. A count and not
      # the points behind it: the page shows no total to hold them against,
      # and a bare "60 points" is a number out of nowhere.
      #
      # Kept beside the reasons rather than in them: `0` is true in Ruby, and a
      # reason picked by its own count would then always be picked.
      def deferral_amounts(record)
        {
          not_due_sheets: not_yet_due_count(record),
          pending_sheets: pending_count(record)
        }
      end

      # A criterion nobody can satisfy any more settles the case; one that is
      # merely unfinished defers it.
      #
      # Additional assignments can change both the reachable points and
      # the points needed for min_percentage, so a passed or failed
      # proposal may change while assignments_complete is false.
      def propose(*statuses)
        return :inconclusive unless @assignments_complete
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

      # points_max_materialized already includes points awaiting marking
      # and points not yet due, so awarding them changes only best_total.
      def points_still_reachable?(record)
        outstanding = outstanding_points(record)
        return false unless outstanding.positive?

        best_total = (record.points_total_materialized || 0) + outstanding

        if rule.min_points_absolute.present?
          best_total >= rule.min_points_absolute
        elsif rule.min_percentage.present?
          max = record.points_max_materialized || 0
          max.positive? && (best_total / max * 100) >= rule.min_percentage
        else
          false
        end
      end

      # Everything that could still bring points: what a tutor has not marked
      # and what nobody has been asked for yet.
      def outstanding_points(record)
        awaiting_marking(record) + not_yet_due(record)
      end

      def awaiting_marking(record)
        @due_points.pending_points_for(record.user_id)
      end

      def not_yet_due(record)
        @due_points.not_yet_due_for(record.user_id)
      end

      def not_yet_due_count(record)
        @due_points.not_yet_due_count_for(record.user_id)
      end

      def pending_count(record)
        @due_points.pending_count_for(record.user_id)
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

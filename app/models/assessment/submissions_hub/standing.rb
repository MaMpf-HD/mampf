module Assessment
  module SubmissionsHub
    # What the exam-admission block reads. The record carries achievements as two
    # id lists, met and not graded yet, and never the value behind one - so
    # "you have 67.3 %" comes alongside rather than out of it.
    Standing = Struct.new(:record, :rule, :achievement_values,
                          :points_still_open, :uses_exam_eligibility,
                          keyword_init: true) do
      def required_achievements
        rule ? rule.required_achievements.to_a : []
      end

      # Not in either list means the lecture graded it and the value fell short.
      def achievement_status(achievement)
        return :unknown unless record
        return :met if achievement.id.in?(record.achievements_met_ids)
        return :ungraded if achievement.id.in?(record.achievements_ungraded_ids)

        :not_met
      end

      def achievement_value(achievement)
        achievement_values[achievement.id]
      end

      def points_total
        record&.points_total_materialized
      end

      def points_max
        record&.points_max_materialized
      end

      def points_pending
        record&.points_max_pending_materialized
      end

      def percentage
        record&.percentage_materialized
      end

      def required_points
        rule&.required_points(record)
      end

      # The best this student could still reach: what is marked plus everything
      # that is not decided yet - which includes sheets nobody has handed in.
      # Below the threshold, nothing they do now changes the outcome, and that
      # is the only place the block says so in red.
      def reachable_points
        return unless points_total

        points_total + (points_still_open || 0)
      end

      def points_out_of_reach?
        needed = required_points
        return false unless needed && reachable_points

        reachable_points < needed
      end
    end
  end
end

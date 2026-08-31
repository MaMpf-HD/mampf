module Assessment
  module SubmissionsHub
    # The exam-admission block: the reader's materialized record, the rule it is
    # measured against and the value recorded for every achievement the lecture
    # keeps. The record carries achievements only as two id lists - met and not
    # graded yet - so the value behind one ("you have 67.3 %") comes separately.
    Standing = Struct.new(:record, :rule, :achievement_values,
                          :uses_exam_eligibility, keyword_init: true) do
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
    end
  end
end

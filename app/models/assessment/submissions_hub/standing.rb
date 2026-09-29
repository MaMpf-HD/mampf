module Assessment
  module SubmissionsHub
    # What the exam-admission block reads. The record carries achievements as two
    # id lists, met and not graded yet, and never the value behind one - so
    # "you have 67.3 %" comes alongside rather than out of it.
    Standing = Struct.new(:record, :rule, :achievement_values,
                          :points_still_open, :points_marked_so_far,
                          :points_awaiting_marks, :sheets_awaiting_marks,
                          :assignments_complete, :uses_exam_eligibility,
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

      # Two maxima live here, and they answer different questions.
      # `points_marked_so_far` is what the reader has been weighed against and
      # is what the block shows; `points_max_at_end` is everything the term
      # will hold and is only ever used to ask whether a threshold can still be
      # reached. They are never to be put over one another.
      def points_max_at_end
        record&.points_max_materialized
      end

      # Not `record.percentage_materialized`: that one is taken of every sheet
      # the lecture has set up, the one still running included, so it measures
      # how far the term has got rather than how the reader is doing.
      def percentage
        return unless points_total && points_marked_so_far.to_f.positive?

        (points_total / points_marked_so_far * 100).round(2)
      end

      # What the rule asks of what has been marked - the mark on the bar.
      def required_points_so_far
        rule&.required_points(points_marked_so_far)
      end

      # What it will ask once every sheet is in - the only threshold a
      # reachability claim may be measured against.
      def required_points_at_end
        rule&.required_points(points_max_at_end)
      end

      # The best this student could still reach: what is marked plus everything
      # that is not decided yet - which includes sheets nobody has handed in.
      # Below the threshold, nothing they do now changes the outcome, and that
      # is the only place the block says so in red.
      def reachable_points
        return unless points_total

        points_total + (points_still_open || 0)
      end

      # Only once the lecture says its sheets are all in. Another sheet lifts
      # what is reachable by its points and the threshold by half of them, so
      # while the list is still growing "out of reach" can turn back into
      # "reachable" - and this sentence is the one place the block passes
      # judgement rather than describing.
      def points_out_of_reach?
        return false unless assignments_complete

        needed = required_points_at_end
        return false unless needed && reachable_points

        reachable_points < needed
      end
    end
  end
end

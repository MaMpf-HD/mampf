module Assessment
  module SubmissionsHub
    # One row of the sheet list: an assignment together with what the reader
    # handed in for it and what has come back. Everything it answers is worked out
    # from what the loader put in it, so it never touches the database - which is
    # also why the state table lives here and not on a model: a row's state is the
    # assignment, the participation and the submission read together, and no one
    # of the three knows the other two.
    Sheet = Struct.new(:assignment, :assessment, :participation, :submission,
                       :tasks, :points_by_task_id, :user, keyword_init: true) do
      # The first line that applies wins, and the order is the whole content of
      # this method. Entered points come before everything below them: sheets
      # have no release step, so a value a tutor wrote shows as soon as it is
      # there, and it must not disappear again while the rest of the sheet is
      # being typed - which is what asking `reviewed?` first would do, because
      # emptying one field puts the participation back to pending.
      # Below the marks the deadline decides: while the sheet is open a hand-in
      # reads "Handed in", and only once it is closed does it start waiting.
      def state
        return :no_points unless assessment&.requires_points
        return :exempt if participation&.exempt?
        return :absent if participation&.absent?
        return :marked if results_visible? && participation.reviewed?
        return :partially_marked if results_visible?
        return :awaiting_marks if participation&.reviewed?
        return :rejected if submission&.accepted == false
        return closed_state if assignment.totally_expired?

        open_state
      end

      # A dash unless there is a number to show. The states that read 0 are the
      # ones where the sheet counts and counts as nothing.
      def points
        case state
        when :marked, :partially_marked then participation&.points_total
        when :absent, :missed, :not_recorded, :rejected then BigDecimal("0")
        end
      end

      def max_points
        assessment&.effective_total_points
      end

      def results_visible?
        participation&.results_visible? || false
      end

      def task_points
        points_by_task_id.values
      end

      def points_for(task)
        points_by_task_id[task.id]&.points
      end

      # `graded_at` and `grader_id` on the participation are written by the demo
      # data and by nothing in the app, so the task points are what actually
      # carries the marking. The first branch takes over by itself the day
      # somebody stamps the participation.
      def marked_at
        return unless participation

        participation.graded_at || latest_task_point&.updated_at
      end

      def marked_by
        return unless participation

        participation.grader || latest_task_point&.grader
      end

      # Late and let through: the row shows its number like any other, but the
      # story behind the number is worth a quiet line. `:rejected` is the other
      # half of the same decision and has a state of its own, because there the
      # points column has nothing of its own to say.
      def accepted_late?
        submission&.too_late? && submission.accepted == true
      end

      def team
        submission ? submission.users.to_a : []
      end

      def partners
        team - [user]
      end

      private

        def latest_task_point
          task_points.select(&:updated_at).max_by(&:updated_at)
        end

        # Nothing more can be handed in, so what the gradebook has on record decides.
        # A file without a `submitted_at` is the one case that costs points without
        # anyone doing anything wrong, which is why it has a state of its own.
        def closed_state
          if participation&.submitted_at
            return submission&.correction.present? ? :correction_uploaded : :awaiting_marks
          end

          submission&.manuscript.present? ? :not_recorded : :missed
        end

        # Still open, so nothing is missing yet - the states here say what the
        # reader can still do about it.
        def open_state
          return :tutor_decides if submission&.too_late? && submission.accepted.nil?
          return :grace_period if assignment.in_grace_period?

          submission&.manuscript.present? ? :handed_in : :nothing_handed_in
        end
    end
  end
end

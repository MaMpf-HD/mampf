module Assessment
  module SubmissionsHub
    # One row of the sheet list. The state table lives here rather than on a
    # model because a row's state is the assignment, the participation and the
    # submission read together, and no one of the three knows the other two.
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

      # Whatever the participation carries is shown. The 0 the other states read
      # is not carried by anything - it is the statement "this sheet counts and
      # counts as nothing", and that takes something having been at stake.
      def points
        case state
        when :marked, :partially_marked then participation&.points_total
        when :absent, :missed, :not_recorded, :rejected
          BigDecimal("0") if scale?
        end
      end

      def max_points
        assessment&.effective_total_points
      end

      # Every assignment gets its assessment the moment it is created and its
      # problems whenever the lecturer gets round to them, so a sheet with no
      # problems on it is not a rare sheet - it is every sheet, for a while.
      # This is what the fold explains when it has no numbers to show.
      def tasks_set_up?
        tasks.any?
      end

      # Whether there is anything to measure against - what a denominator and a
      # bar need, and a different question from the one above: a task may be
      # worth 0 and `Assessment::TaskPoint` puts no ceiling on what a tutor may
      # award, so a sheet can carry points with no scale to read them on.
      def scale?
        max_points.to_f.positive?
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

      # A participation may carry no stamp of its own; the task points always
      # carry when they were written, so they answer where it does not.
      def marked_at
        return unless participation

        participation.graded_at || latest_task_point&.updated_at
      end

      def marked_by
        return unless participation

        participation.grader || latest_task_point&.grader
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

        # A file without a `submitted_at` costs points without anybody having done
        # anything wrong, which is why it has a state of its own.
        def closed_state
          if participation&.submitted_at
            return submission&.correction.present? ? :correction_uploaded : :awaiting_marks
          end

          submission&.manuscript.present? ? :not_recorded : :missed
        end

        def open_state
          return :tutor_decides if submission&.too_late? && submission.accepted.nil?
          return :grace_period if assignment.in_grace_period?

          submission&.manuscript.present? ? :handed_in : :nothing_handed_in
        end
    end
  end
end

module Assessment
  # The rows of a table: one participation per person on the roster, the
  # missing ones created on the way. Drawing a table writes - a deliberate
  # exception - because speakers and candidates reach a roster in bulk, past
  # any callback, and a row without an id could not be graded through its
  # route; a test's and an achievement's tables come here for the same
  # reason, a sheet's for the re-homing. Idempotent on the unique index.
  class ParticipationIndex
    class << self
      # Returns a hash keyed by [assessment_id, user_id], in the pairs' order.
      def build(pairs)
        pairs = pairs.reject { |assessment, user| assessment.nil? || user.nil? }
        return {} if pairs.empty?

        index = Participation
                .includes(:user, :grader, :task_points, assessment: [:assessable, :tasks])
                .where(assessment_id: pairs.map { |a, _| a.id }.uniq,
                       user_id: pairs.map { |_, u| u.id }.uniq)
                .index_by { |p| [p.assessment_id, p.user_id] }

        pairs.each_with_object({}) do |(assessment, user), rows|
          key = [assessment.id, user.id]
          rows[key] ||= index[key] || create_participation(assessment, user)
        end
      end

      # The rows of a roster in one go: the missing ones seeded in one
      # statement, all of them loaded by user, and the blank ones handed to
      # the group each person is in now. `groups` maps every user id to their
      # tutorial, nil for none.
      def rows_for(assessment, users, groups)
        assessment.seed_participations_from!(
          user_ids: users.map(&:id),
          tutorial_mapping: users.to_h { |user| [user.id, groups[user.id]&.id] },
          recompute: false
        )
        rows = load_rows(assessment, users.map(&:id))
        rehome_blank_rows(rows, groups)
        rows
      end

      def load_rows(assessment, user_ids)
        Participation.where(user_id: user_ids, assessment: assessment)
                     .includes(:user, :task_points, :tutorial, :assessment)
                     .index_by(&:user_id)
      end

      # Blank participations must follow tutorial membership so the current
      # tutor can enter points; recorded work must stay with its original
      # tutorial. Points may land on the row between this page's read and its
      # write, so the row is read again under the lock the point entry takes.
      def rehome_blank_rows(rows, groups)
        rows.each_value do |row|
          next unless groups.key?(row.user_id) && blank?(row)
          next if row.tutorial_id == groups[row.user_id]&.id

          row.with_lock { row.update!(tutorial: groups[row.user_id]) if blank?(row) }
        end
      end

      # The group whose tutor may write on the row: the student's current one
      # while the row is blank, the one that holds the recorded work after.
      def group_holding(row)
        return row.tutorial unless blank?(row)

        TutorialMembership.find_by(user_id: row.user_id,
                                   lecture_id: row.assessment.lecture_id)&.tutorial
      end

      # One row, under a lock the caller holds: a value written after the
      # student changed groups belongs to the new group, whether or not a
      # table has been drawn since.
      def follow_membership(row)
        group = group_holding(row)
        row.update!(tutorial: group) if row.tutorial_id != group&.id
      end

      # Points taken back again leave task points of nil behind; those carry
      # nothing either. An achievement's row is blank while no value is entered.
      def blank?(row)
        row.pending? && row.submitted_at.nil? && !row.results_visible? && row.grade_text.blank?
      end

      # Concurrent requests may hit either the uniqueness validation or the index;
      # both must reuse the existing participation.
      def create_participation(assessment, user, tutorial: nil)
        Participation.create!(assessment_id: assessment.id, user_id: user.id,
                              tutorial_id: tutorial&.id, status: :pending)
      rescue ActiveRecord::RecordNotUnique
        Participation.find_by!(assessment_id: assessment.id, user_id: user.id)
      rescue ActiveRecord::RecordInvalid => e
        raise unless e.record.errors.of_kind?(:user_id, :taken)

        Participation.find_by!(assessment_id: assessment.id, user_id: user.id)
      end
    end
  end
end

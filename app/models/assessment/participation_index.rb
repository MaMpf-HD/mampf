module Assessment
  # The rows of a talk's or an exam's table: one participation per person on
  # the roster, the missing ones created on the way. Drawing the table writes
  # - a deliberate exception - because speakers and candidates reach a roster
  # in bulk, past any callback, and a row without an id could not be graded
  # through its route. Idempotent on the unique index.
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

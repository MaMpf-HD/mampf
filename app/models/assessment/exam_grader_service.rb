module Assessment
  # Handles participation lookup/creation for exam grading and pointing.
  class ExamGraderService
    class ExamGraderError < StandardError; end

    class << self
      def find_participation(assessment, user)
        return if assessment.nil? || user.nil?

        Participation.find_by(
          assessment_id: assessment.id,
          user_id: user.id
        )
      end

      def init_participation(assessment, user)
        return if assessment.nil? || user.nil?

        Participation.find_by(assessment_id: assessment.id, user_id: user.id) ||
          create_participation(assessment, user)
      end

      def create_participation(assessment, user)
        Participation.create!(assessment_id: assessment.id, user_id: user.id, status: :pending)
      rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
        Participation.find_by!(assessment_id: assessment.id, user_id: user.id)
      end

      # Given [assessment, user] pairs, loads all existing participations
      # and creates only the missing ones.
      # Returns a hash keyed by [assessment_id, user_id].
      def init_participations(pairs)
        pairs = pairs.reject { |assessment, user| assessment.nil? || user.nil? }
        return {} if pairs.empty?

        assessment_ids = pairs.map { |assessment, _user| assessment.id }.uniq
        user_ids = pairs.map { |_assessment, user| user.id }.uniq

        index = Participation
                .where(assessment_id: assessment_ids, user_id: user_ids)
                .index_by { |p| [p.assessment_id, p.user_id] }

        pairs.each_with_object(index) do |(assessment, user), memo|
          key = [assessment.id, user.id]
          next if memo.key?(key)

          memo[key] = create_participation(assessment, user)
        end
      end
    end
  end
end

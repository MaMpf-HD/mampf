module StudentPerformance
  class ComputationService
    attr_reader :lecture

    def initialize(lecture:)
      @lecture = lecture
    end

    def compute_and_upsert_record_for(user)
      totals = aggregate_points(user)
      met_ids = achievement_ids_met_by(user)

      upsert_record(
        user: user,
        points_total: totals[:points_total],
        points_max: totals[:points_max],
        achievements_met_ids: met_ids
      )
    end

    def compute_and_upsert_all_records!
      lecture.members.find_each do |user|
        compute_and_upsert_record_for(user)
      end
    end

    private

      def assessments
        @assessments ||= Assessment::Assessment.where(lecture_id: lecture.id)
      end

      def aggregate_points(user)
        participation_ids = Assessment::Participation
                            .where(assessment_id: assessments.select(:id), user_id: user.id)
                            .pluck(:id)

        points_total = if participation_ids.any?
          Assessment::TaskPoint
            .where(assessment_participation_id: participation_ids)
            .sum(:points)
        else
          BigDecimal("0")
        end

        points_max = assessments.sum(&:effective_total_points)

        { points_total: points_total, points_max: points_max }
      end

      def achievement_ids_met_by(_user)
        []
      end

      def compute_percentage(points_total, points_max)
        return nil if points_max.nil? || points_max.zero?

        (points_total / points_max * 100).round(2)
      end

      def upsert_record(user:, points_total:, points_max:, achievements_met_ids:)
        now = Time.current
        percentage = compute_percentage(points_total, points_max)

        # All values are computed by this service, not user input.
        # Uniqueness is enforced by the DB index on [lecture_id, user_id]
        # rubocop:disable Rails/SkipsModelValidations
        Record.upsert(
          {
            lecture_id: lecture.id,
            user_id: user.id,
            points_total_materialized: points_total,
            points_max_materialized: points_max,
            percentage_materialized: percentage,
            achievements_met_ids: achievements_met_ids,
            computed_at: now,
            updated_at: now
          },
          unique_by: [:lecture_id, :user_id]
        )
        # rubocop:enable Rails/SkipsModelValidations
      end
  end
end

module StudentPerformance
  class ComputationService
    attr_reader :lecture

    def initialize(lecture:)
      @lecture = lecture
    end

    def compute_and_upsert_record_for(user)
      stats = aggregate_points(user)
      met_ids = achievement_ids_met_by(user)

      upsert_record(
        user: user,
        points_total: stats[:points_total],
        points_max: stats[:points_max],
        achievements_met_ids: met_ids,
        counts: stats[:counts]
      )
    end

    def compute_and_upsert_all_records!
      lecture.members.find_each do |user|
        compute_and_upsert_record_for(user)
      end
    end

    private

      def assessments
        @assessments ||= Assessment::Assessment
                         .where(lecture_id: lecture.id)
                         .includes(:tasks)
      end

      def aggregate_points(user)
        participations = Assessment::Participation
                         .where(assessment_id: assessments.select(:id), user_id: user.id)
                         .select(:id, :assessment_id, :status)

        status_map = participations.group_by(&:status)
        reviewed = status_map.fetch("reviewed", [])
        exempt = status_map.fetch("exempt", [])

        reviewed_ids = reviewed.map(&:id)
        exempt_assessment_ids = exempt.to_set(&:assessment_id)

        points_total = if reviewed_ids.any?
          Assessment::TaskPoint
            .where(assessment_participation_id: reviewed_ids)
            .sum(:points)
        else
          BigDecimal("0")
        end

        non_exempt = assessments.reject { |a| exempt_assessment_ids.include?(a.id) }
        points_max = non_exempt.sum { |a| effective_max(a) }

        participated_ids = participations.to_set(&:assessment_id)
        no_participation = assessments.count { |a| participated_ids.exclude?(a.id) }

        counts = {
          total: assessments.size,
          reviewed: reviewed.size,
          pending: status_map.fetch("pending", []).size + no_participation,
          exempt: exempt.size
        }

        { points_total: points_total, points_max: points_max, counts: counts }
      end

      def achievement_ids_met_by(_user)
        []
      end

      def effective_max(assessment)
        assessment.total_points || assessment.tasks.sum(&:max_points)
      end

      def compute_percentage(points_total, points_max)
        return nil if points_max.nil? || points_max.zero?

        (points_total / points_max * 100).round(2)
      end

      def upsert_record(user:, points_total:, points_max:, achievements_met_ids:, counts:)
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
            assessments_total_count: counts[:total],
            assessments_reviewed_count: counts[:reviewed],
            assessments_pending_count: counts[:pending],
            assessments_exempt_count: counts[:exempt],
            computed_at: now,
            updated_at: now
          },
          unique_by: [:lecture_id, :user_id]
        )
        # rubocop:enable Rails/SkipsModelValidations
      end
  end
end

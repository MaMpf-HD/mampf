module StudentPerformance
  # Computes the performance metrics for students in a lecture and
  # upserts the results into the database.
  class ComputationService
    attr_reader :lecture

    UPSERT_BATCH_SIZE = 100

    def initialize(lecture:)
      @lecture = lecture
    end

    def compute_and_upsert_record_for(user)
      return unless lecture.members.exists?(id: user.id)

      stats = aggregate_points(user)
      grade_texts = achievement_grade_texts_for(user.id)
      met_ids = achievement_ids_met(grade_texts)
      ungraded_ids = achievement_ids_ungraded(grade_texts)

      upsert_records([build_row(user.id, stats, met_ids, ungraded_ids)])
    end

    def compute_and_upsert_all_records!
      user_ids = lecture.members.pluck(:id)
      return if user_ids.empty?

      participations_by_user = prefetch_participations(user_ids)

      rows = user_ids.map do |uid|
        parts = participations_by_user.fetch(uid, [])
        stats = aggregate_points_from(parts)
        grade_texts = achievement_participations_cache.fetch(uid, {})
        met_ids = achievement_ids_met(grade_texts)
        ungraded_ids = achievement_ids_ungraded(grade_texts)
        build_row(uid, stats, met_ids, ungraded_ids)
      end

      rows.each_slice(UPSERT_BATCH_SIZE) do |batch|
        upsert_records(batch)
      end
    end

    private

      # Assignments only. Exams carry points as well, but exam eligibility is
      # earned from assignments, so exam points never count towards it.
      def assessments
        @assessments ||= Assessment::Assessment
                         .where(lecture_id: lecture.id,
                                assessable_type: "Assignment")
                         .includes(:tasks)
      end

      def prefetch_participations(user_ids)
        Assessment::Participation
          .where(assessment_id: assessments.select(:id),
                 user_id: user_ids)
          .select(:id, :assessment_id, :status, :submitted_at, :user_id,
                  :points_total)
          .group_by(&:user_id)
      end

      def aggregate_points_from(participations)
        status_map = participations.group_by(&:status)
        reviewed = status_map.fetch("reviewed", [])
        exempt = status_map.fetch("exempt", [])

        points_total = reviewed.sum { |p| p.points_total || BigDecimal("0") }

        exempt_assessment_ids = exempt.to_set(&:assessment_id)
        non_exempt = assessments.reject do |a|
          exempt_assessment_ids.include?(a.id)
        end
        points_max = non_exempt.sum(&:effective_total_points)

        {
          points_total: points_total,
          points_max: points_max,
          points_max_pending: pending_points(status_map, non_exempt)
        }
      end

      # What is handed in but not marked yet. Without it a marking backlog is
      # indistinguishable from work never done, and eligibility reads it as a
      # fail. A submission counts as awaiting marking until every one of its
      # tasks is scored, which is what leaves the participation on `pending`.
      def pending_points(status_map, non_exempt)
        awaiting = status_map.fetch("pending", [])
                             .select { |p| p.submitted_at.present? }
                             .to_set(&:assessment_id)
        return BigDecimal("0") if awaiting.empty?

        non_exempt.select { |a| awaiting.include?(a.id) }
                  .sum(&:effective_total_points)
      end

      def aggregate_points(user)
        participations = Assessment::Participation
                         .where(assessment_id: assessments.select(:id),
                                user_id: user.id)
                         .select(:id, :assessment_id, :status, :submitted_at,
                                 :user_id, :points_total)
                         .to_a

        aggregate_points_from(participations)
      end

      def lecture_achievements
        @lecture_achievements ||= Achievement
                                  .where(lecture_id: lecture.id)
                                  .includes(:assessment)
      end

      def achievement_ids_met(grade_texts)
        return [] if lecture_achievements.empty?

        lecture_achievements.select do |a|
          a.assessment && a.met_by?(grade_texts[a.assessment.id])
        end.map(&:id)
      end

      def achievement_ids_ungraded(grade_texts)
        return [] if lecture_achievements.empty?

        graded_assessment_ids = grade_texts.keys.to_set

        lecture_achievements.reject do |a|
          a.assessment.nil? ||
            graded_assessment_ids.include?(a.assessment.id)
        end.map(&:id)
      end

      def achievement_grade_texts_for(user_id)
        a_ids = lecture_achievements.filter_map { |a| a.assessment&.id }
        return {} if a_ids.empty?

        Assessment::Participation
          .where(assessment_id: a_ids, user_id: user_id)
          .where.not(grade_text: [nil, ""])
          .pluck(:assessment_id, :grade_text)
          .to_h
      end

      def achievement_participations_cache
        @achievement_participations_cache ||= begin
          a_ids = lecture_achievements.filter_map { |a| a.assessment&.id }
          if a_ids.empty?
            {}
          else
            Assessment::Participation
              .where(assessment_id: a_ids)
              .where.not(grade_text: [nil, ""])
              .pluck(:user_id, :assessment_id, :grade_text)
              .group_by(&:first)
              .transform_values do |rows|
                rows.to_h { |_, aid, gt| [aid, gt] }
              end
          end
        end
      end

      def compute_percentage(points_total, points_max)
        return nil if points_max.nil? || points_max.zero?

        (points_total / points_max * 100).round(2)
      end

      def build_row(user_id, stats, achievements_met_ids,
                    achievements_ungraded_ids)
        now = Time.current
        percentage = compute_percentage(
          stats[:points_total], stats[:points_max]
        )

        {
          lecture_id: lecture.id,
          user_id: user_id,
          points_total_materialized: stats[:points_total],
          points_max_materialized: stats[:points_max],
          points_max_pending_materialized: stats[:points_max_pending],
          percentage_materialized: percentage,
          achievements_met_ids: achievements_met_ids,
          achievements_ungraded_ids: achievements_ungraded_ids,
          computed_at: now
        }
      end

      # rubocop:disable Rails/SkipsModelValidations
      def upsert_records(rows)
        Record.upsert_all(rows, unique_by: [:lecture_id, :user_id])
      end

    # rubocop:enable Rails/SkipsModelValidations
  end
end

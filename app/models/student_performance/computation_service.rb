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
      stats = aggregate_points(user)
      met_ids = achievement_ids_met_by(user)

      upsert_records([build_row(user.id, stats, met_ids)])
    end

    def compute_and_upsert_all_records!
      user_ids = lecture.members.pluck(:id)
      return if user_ids.empty?

      participations_by_user = prefetch_participations(user_ids)
      points_by_participation = prefetch_task_points(
        participations_by_user.values.flatten
      )

      rows = user_ids.map do |uid|
        parts = participations_by_user.fetch(uid, [])
        stats = aggregate_from_prefetched(parts, points_by_participation)
        met_ids = achievement_ids_met_by_id(uid)
        build_row(uid, stats, met_ids)
      end

      rows.each_slice(UPSERT_BATCH_SIZE) do |batch|
        upsert_records(batch)
      end
    end

    private

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
          .select(:id, :assessment_id, :status, :submitted_at, :user_id)
          .group_by(&:user_id)
      end

      def prefetch_task_points(participations)
        reviewed_ids = participations
                       .select { |p| p.status == "reviewed" }
                       .map(&:id)
        return {} if reviewed_ids.empty?

        Assessment::TaskPoint
          .where(assessment_participation_id: reviewed_ids)
          .group(:assessment_participation_id)
          .sum(:points)
      end

      def aggregate_from_prefetched(participations, points_lookup)
        status_map = participations.group_by(&:status)
        reviewed = status_map.fetch("reviewed", [])
        exempt = status_map.fetch("exempt", [])
        pending_all = status_map.fetch("pending", [])

        points_total = reviewed.sum do |p|
          points_lookup.fetch(p.id, BigDecimal("0"))
        end

        exempt_assessment_ids = exempt.to_set(&:assessment_id)
        non_exempt = assessments.reject do |a|
          exempt_assessment_ids.include?(a.id)
        end
        points_max = non_exempt.sum { |a| effective_max(a) }

        participated_ids = participations.to_set(&:assessment_id)
        no_participation = assessments.count do |a|
          participated_ids.exclude?(a.id)
        end

        pending_grading = pending_all.count { |p| p.submitted_at.present? }
        not_submitted = pending_all.count { |p| p.submitted_at.nil? } +
                        no_participation

        counts = {
          total: assessments.size,
          reviewed: reviewed.size,
          pending_grading: pending_grading,
          not_submitted: not_submitted,
          exempt: exempt.size
        }

        { points_total: points_total, points_max: points_max, counts: counts }
      end

      def aggregate_points(user)
        participations = Assessment::Participation
                         .where(assessment_id: assessments.select(:id),
                                user_id: user.id)
                         .select(:id, :assessment_id, :status, :submitted_at,
                                 :user_id)
                         .to_a

        points_lookup = prefetch_task_points(participations)
        aggregate_from_prefetched(participations, points_lookup)
      end

      def lecture_achievements
        @lecture_achievements ||= Achievement
                                  .where(lecture_id: lecture.id)
                                  .includes(:assessment)
      end

      def achievement_ids_met_by(user)
        lecture_achievements.select do |a|
          a.student_met_threshold?(user)
        end.map(&:id)
      end

      def achievement_ids_met_by_id(user_id)
        return [] if lecture_achievements.empty?

        assessment_ids = lecture_achievements.filter_map do |a|
          a.assessment&.id
        end
        return [] if assessment_ids.empty?

        grade_texts = achievement_participations_cache
                      .fetch(user_id, {})

        lecture_achievements.select do |a|
          next false unless a.assessment

          gt = grade_texts[a.assessment.id]
          next false if gt.blank?

          case a.value_type
          when "boolean"    then gt == "pass"
          when "numeric"    then gt.to_i >= a.threshold
          when "percentage" then gt.to_f >= a.threshold
          end
        end.map(&:id)
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

      def effective_max(assessment)
        assessment.total_points || assessment.tasks.sum(&:max_points)
      end

      def compute_percentage(points_total, points_max)
        return nil if points_max.nil? || points_max.zero?

        (points_total / points_max * 100).round(2)
      end

      def build_row(user_id, stats, achievements_met_ids)
        now = Time.current
        percentage = compute_percentage(
          stats[:points_total], stats[:points_max]
        )

        {
          lecture_id: lecture.id,
          user_id: user_id,
          points_total_materialized: stats[:points_total],
          points_max_materialized: stats[:points_max],
          percentage_materialized: percentage,
          achievements_met_ids: achievements_met_ids,
          assessments_total_count: stats[:counts][:total],
          assessments_reviewed_count: stats[:counts][:reviewed],
          assessments_pending_grading_count:
            stats[:counts][:pending_grading],
          assessments_not_submitted_count:
            stats[:counts][:not_submitted],
          assessments_exempt_count: stats[:counts][:exempt],
          computed_at: now,
          updated_at: now
        }
      end

      # rubocop:disable Rails/SkipsModelValidations
      def upsert_records(rows)
        Record.upsert_all(rows, unique_by: [:lecture_id, :user_id])
      end

    # rubocop:enable Rails/SkipsModelValidations
  end
end

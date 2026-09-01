# Responsible for backfilling assessment participations for expired assignments
class AssessmentBackfillWorker
  include Sidekiq::Worker

  # The job runs every minute and in the steady state has to find nothing, so
  # the search is one anti-join rather than a scan plus four queries per
  # assignment. Raw SQL because "every roster member without a participation"
  # has no ActiveRecord form.
  MISSING_PARTICIPATIONS_SQL = <<~SQL.squish.freeze
    SELECT DISTINCT a.id AS assessment_id, tm.user_id, tm.tutorial_id
      FROM assessment_assessments a
      JOIN assignments asg ON asg.id = a.assessable_id
                          AND a.assessable_type = 'Assignment'
      JOIN lectures l ON l.id = a.lecture_id
      JOIN tutorial_memberships tm ON tm.lecture_id = a.lecture_id
      LEFT JOIN assessment_participations p ON p.assessment_id = a.id
                                           AND p.user_id = tm.user_id
     WHERE asg.deadline < :now
       AND l.submission_deletion_date >= :today
       AND p.id IS NULL
  SQL

  def perform
    missing_participations.each do |assessment_id, rows|
      backfill_assessment(assessment_id, rows)
    end
  end

  private

    def missing_participations
      sql = ApplicationRecord.sanitize_sql_array(
        [MISSING_PARTICIPATIONS_SQL, { now: Time.current, today: Date.current }]
      )

      ApplicationRecord.connection
                       .select_all(sql)
                       .group_by { |row| row["assessment_id"] }
    end

    def backfill_assessment(assessment_id, rows)
      assessment = ::Assessment::Assessment.find_by(id: assessment_id)
      return unless assessment

      assessment.seed_participations_from!(
        user_ids: rows.pluck("user_id"),
        tutorial_mapping: rows.to_h { |row| [row["user_id"], row["tutorial_id"]] }
      )
    end
end

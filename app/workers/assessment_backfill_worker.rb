class AssessmentBackfillWorker
  include Sidekiq::Worker

  def perform
    return unless Flipper.enabled?(:assessment_grading)

    Assignment.expired
              .joins(:assessment)
              .where(assessment_assessments: { backfilled_at: nil })
              .find_each do |assignment|
      backfill_assignment(assignment)
    end
  end

  private

    def backfill_assignment(assignment)
      assessment = assignment.assessment
      return unless assessment

      lecture = assignment.lecture
      memberships = TutorialMembership.where(
        tutorial_id: lecture.tutorial_ids
      )

      return if memberships.none?

      tutorial_mapping = memberships.pluck(:user_id, :tutorial_id).to_h
      roster_user_ids = tutorial_mapping.keys

      assessment.seed_participations_from!(
        user_ids: roster_user_ids,
        tutorial_mapping: tutorial_mapping
      )

      assessment.update_column(:backfilled_at, Time.current) # rubocop:disable Rails/SkipsModelValidations
    end
end

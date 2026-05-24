# Represents a user's official membership in a lecture's roster, distinct from
# casual subscriptions, and tracks the source campaign for automated management.
class LectureMembership < ApplicationRecord
  belongs_to :user
  belongs_to :lecture
  belongs_to :source_campaign, class_name: "Registration::Campaign", optional: true

  after_commit :sync_student_performance, on: :create
  after_commit :delete_performance_record, on: :destroy

  private

    def sync_student_performance
      lecture.sync_student_performance_for_members!([user_id])
    end

    def delete_performance_record
      return unless Flipper.enabled?(:assessment_grading)

      StudentPerformance::Record
        .where(lecture_id: lecture_id, user_id: user_id)
        .delete_all
    end
end
